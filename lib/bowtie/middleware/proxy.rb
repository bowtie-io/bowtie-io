module Bowtie::Middleware
  class Proxy
    def initialize(*args)
      @platform = Platform.new(*args)
      @backend  = Backend.new(*args)
    end

    def call(env)
      status, headers, body = @platform.call(env)

      if status.to_i == 305
        env[:proxy_addon_headers] = JSON.load(headers['X-Bowtie-Client-Proxy-Headers'])
        env[:proxy_location] = headers['Location']
        @backend.call(env)
      else
        [status, headers, body]
      end
    end
  end

  private
  class Backend < Rack::StreamingProxy::Proxy
    def destination_uri(rack_request)
      rack_request.env[:proxy_location]
    end
  end

  class Platform < Rack::StreamingProxy::Proxy
    def destination_uri(rack_request)
      fqdn     = Bowtie::Settings['project']['fqdn']['development']
      base_url = "https://#{fqdn}"
      path     = rack_request.path

      rack_request.env[:proxy_addon_headers] = {
        'X-Forwarded-Host'        => rack_request.host_with_port,
        'X-Forwarded-Port'        => rack_request.port,
        'X-Forwarded-Proto'       => 'http',
        'X-Forwarded-Scheme'      => 'http',
        'X-Bowtie-Client-Version' => Bowtie::VERSION
      }

      uri = URI.join(base_url, path)
      uri.query = rack_request.query_string
      uri.to_s
    end
  end
end
