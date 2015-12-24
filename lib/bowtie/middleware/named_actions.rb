module Bowtie::Middleware
  class NamedActions
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      action = headers['X-Bowtie-Client-Named-Action']

      if action == 'sign_in'
        location_override_path = Bowtie::Settings['users']['after_sign_in_path'] rescue nil
      elsif action == 'sign_up'
        location_override_path = Bowtie::Settings['users']['after_sign_up_path'] rescue nil
      elsif action == 'sign_out'
        location_override_path = Bowtie::Settings['users']['after_sign_out_path'] rescue nil
      end

      if location_override_path
        location = URI(headers['Location'])
        location.path = location_override_path
        headers.merge!('Location' => location.to_s)
      end

      [status, headers, response]
    end
  end
end
