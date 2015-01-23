module Bowtie::Middleware
  class Proxy < Rack::StreamingProxy::Proxy
    def destination_uri(rack_request)
      fqdn     = Bowtie::Settings['project']['fqdn']['development']
      base_url = "https://#{fqdn}"
      path     = rack_request.path

      rack_request.env[:proxy_addon_headers] = {
        'X-Forwarded-Host' => fqdn
      }

      URI.join(base_url, path).to_s
    end
  end
end
