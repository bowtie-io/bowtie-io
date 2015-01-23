# Rewrites header values referencing the fqdn to make redirects behave
# nicely without requiring overrides on the BowTie platform.

module Bowtie::Middleware
  class Rewrite
    def initialize(app, options)
      @app             = app
      @remote_base_url = "https://#{Bowtie::Settings['project']['fqdn']['development']}"
      @local_base_url  = "http://#{options['host']}:#{options['port']}"
    end

    def call(env)
      status, headers, response = @app.call(env)

      headers.each do |k, v|
        headers[k] = v.gsub(@remote_base_url, @local_base_url)
      end

      [status, headers, response]
    end
  end
end
