# Checks .bowtie.yml policy definitions to permit or deny access
# to the requested resource.

require 'listen'

module Bowtie::Middleware
  class PolicyCheck
    def self.watch!
      source = Jekyll.configuration['source']

      # Initialize our policies with current source
      Policy.load_policies!(source)

      # Watch for policy file changes and reload policies on change
      Listen.to(source, only: /\.bowtie\.yml/){
        begin
          Policy.load_policies!(source)
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
      }.start
    end

    def initialize(app)
      @app               = app

    end

    def call(env)
      rack_request = Rack::Request.new(env)
      status, headers, response = @app.call(env)

      if Policy.permits?(rack_request)
        [status, headers, response]
      else
        [403, {}, ["Request not permitted by defined policies"]]
      end
    end

    private
    module Loader
      extend self

      CONFIG_FILE_NAME   = '.bowtie.yml'
      CONFIG_BLOCK_KEY   = 'permits'
      CONFIG_METHODS_KEY = 'method'
      CONFIG_PLANS_KEY   = 'plans'
      CONFIG_PATH_KEY    = 'path'
      CONFIG_PROFILE_KEY = 'profile'
      CONFIG_STATUS_KEY  = 'status'

      def policy_records(source)
        records = Dir["#{source}/**/.bowtie.yml"].collect { |path|
          policy_records_for_path(path.gsub(source, ''), File.read(path))
        }.compact.flatten

        records << default_permit_all if records.length == 0

        records
      end

      def default_permit_all
        Policy.new('',
                   nil,
                   nil,
                   0,
                   nil)
      end

      def policy_records_for_path(path, content)
        base_path = path.gsub(CONFIG_FILE_NAME, '')
        base_path = "/#{base_path}" unless base_path.start_with? '/'
        base_path = base_path[0..-2] if base_path.end_with? '/'

        environment_config = YAML.load(content) || {}

        permitted_section_configs = environment_config[CONFIG_BLOCK_KEY] || []
        permitted_section_configs = [permitted_section_configs] unless permitted_section_configs.is_a? Array

        policy_records_from_permitted_section_configs(base_path, permitted_section_configs)
      end

      def policy_records_from_permitted_section_configs(base_path, configs)
        records = []

        configs.each do |config|
          records += policy_records_from_permitted_section_config(base_path, config)
        end

        return records
      end

      def policy_records_from_permitted_section_config(base_path, config)
        path_extension = config[CONFIG_PATH_KEY]
        path_extension = path_extension[1..-1] if path_extension && path_extension.start_with?('/')

        policy_path = [base_path, path_extension].compact.join('/')

        methods = methods_from_permitted_section_config(config)
        plans   = plans_from_permitted_section_config(config)
        profile_restrictions = profile_restrictions_from_permitted_section_config(config)
        status = status_from_permitted_section_config(config)

        records = []

        methods.each do |method|
          plans.each do |plan|
            records << Policy.new(policy_path,
                                  method,
                                  plan,
                                  policy_path.length,
                                  profile_restrictions,
                                  status)
          end
        end

        return records
      end

      def methods_from_permitted_section_config(config)
        method_config = config[CONFIG_METHODS_KEY]

        if method_config.nil? || method_config == '*'
          [nil]
        else
          if method_config.is_a? Array
            method_config.map(&:upcase)
          elsif method_config.is_a? String
            [method_config].map(&:upcase)
          else
            []
          end
        end
      end

      def plans_from_permitted_section_config(config)
        plan_config = config[CONFIG_PLANS_KEY]

        if plan_config.nil? || plan_config == '*'
          [nil]
        else
          if plan_config.is_a? Array
            plan_config
          else
            [plan_config]
          end
        end
      end

      def profile_restrictions_from_permitted_section_config(config)
        _profile_restrictions_config = config[CONFIG_PROFILE_KEY]
      end

      def status_from_permitted_section_config(config)
        status_config = config[CONFIG_STATUS_KEY]

        if status_config.nil? || status_config == '*'
          nil
        else
          status_config
        end
      end
    end

    Policy = Struct.new(:path,
                        :request_method,
                        :plan,
                        :weight,
                        :profile_restrictions,
                        :status) do
      class << self
        attr_reader :all

        def load_policies!(source)
          @all = Loader.policy_records(source)
        end

        def permits?(rack_request)
          policies = applicable_for(rack_request)

          # When there's no applicable policy, the request is not permitted
          return false if policies.length == 0

          !!policies.detect { |policy|
            policy.permits?(rack_request)
          }
        end

        def applicable_for(rack_request)
          applicable_to_request = all.select { |policy|
            rack_request.path.start_with?(policy.path)
          }.sort_by!(&:weight).reverse

          heaviest = applicable_to_request.first

          applicable_to_request.select { |policy|
            policy.weight >= heaviest.weight
          }
        end
      end

      def permits?(rack_request)
        request_method_permitted?(rack_request) &&
          plan_permitted?(rack_request) &&
          profile_permitted?(rack_request) &&
          status_permitted?(rack_request)
      end

      private
      def request_method_permitted?(rack_request)
        request_method.nil? ||
          request_method == rack_request.request_method
      end

      def plan_permitted?(rack_request)
        plan.nil? ||
          (rack_request.env['rack.session']['user']['stripe_plan_id'] rescue nil) == plan
      end

      def profile_permitted?(rack_request)
        if profile_restrictions.nil?
          true
        else
          profile_restrictions.each do |scope,values|
            profile_data = user_profile(rack_request, scope)
            return false if profile_data.nil?

            values.each do |key, value|
              if value == true
                return false if !profile_data[key]
              elsif value == false
                return false if !!profile_data[key]
              else
                return false if profile_data[key] != value
              end
            end
          end

          return true
        end
      end

      def status_permitted?(rack_request)
        status.nil? ||
          (rack_request.env['rack.session']['user']['status'] rescue nil) == status
      end

      def user_profile(rack_request, scope)
        user_id = rack_request.env['rack.session']['user']['id'] rescue nil
        return nil if user_id.nil?

        response = RestClient.get(user_profile_endpoint_url(user_id, scope))
        JSON.parse(response.body)
      end

      def user_profile_endpoint_url(user_id, scope)
        secret_key = Bowtie::Settings['project']['secret_key'] rescue nil
        secret_key ||= Bowtie::Settings['project']['environments']['development']['secret_key'] rescue nil
        secret_key ||= Bowtie::Settings['client']['secret_key'] rescue nil

        raise SecretKeyMissingError.new if secret_key.nil?

        URI::HTTPS.build(host: Bowtie::Settings['client']['fqdn'],
                         userinfo: "#{Bowtie::Settings['project']['secret_key']}:",
                         path: "/bowtie/api/users/#{user_id}/profile.json",
                         query: "scope=#{scope}").to_s
      end
    end
  end
end

