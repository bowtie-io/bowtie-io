module Bowtie::Middleware
  class Proxy
    def initialize(*args)
      @platform = Platform.new
      @backend  = Backend.new
    end

    def call(env)
      status, headers, body = @platform.call(env)

      if status.to_i == 305
        env[:proxy_addon_headers] = JSON.load(headers['X-Bowtie-Client-Proxy-Headers'].first)
        env[:proxy_location] = headers['Location'].first
        @backend.call(env)
      else
        [status, headers, body]
      end
    end
  end

  private
  class Backend < Rack::Proxy
    def self.extract_http_request_headers(env)
      addon_headers = env[:proxy_addon_headers].inject({}) { |h,v| h[v[0]] = v[1].to_s; h }
      super(env).merge!(addon_headers)
    end

    protected
    def perform_request(env)
      @backend = URI(env[:proxy_location])

      env['REQUEST_URI'] = @backend.request_uri
      env['HTTP_HOST']   = @backend.host

      super(env)
    end
  end

  class Platform < Rack::Proxy
    def rewrite_env(env)
      rack_request = Rack::Request.new(env)

      env['HTTPS']       = 'on'
      env['SERVER_PORT'] = 443
      env['HTTP_HOST']   = Bowtie::Settings['client']['fqdn']

      env['HTTP_X_FORWARDED_HOST']        = rack_request.host_with_port
      env['HTTP_X_FORWARDED_PROTO']       = rack_request.port.to_s
      env['HTTP_X_FORWARDED_SCHEME']      = 'http'
      env['HTTP_X_BOWTIE_CLIENT_VERSION'] = Bowtie::VERSION

      env
    end

    def rewrite_response(triplet)
      status, headers, body = triplet

      headers.delete('Transfer-Encoding')

      [status, headers, body]
    end

    protected
    def perform_request(env)
       super(env)
    end
  end
end
