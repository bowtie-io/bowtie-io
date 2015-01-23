module Bowtie::Middleware
  class Rewrite
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      fqdn     = Bowtie::Settings['project']['fqdn']['development']
      base_url = "https://#{fqdn}"

      headers.each do |k, v|
        headers[k] = v.gsub(base_url, 'http://localhost:8080')
      end

      [status, headers, response]
    end
  end
end
