module Bowtie
  class DevelopmentProxy < Rack::StreamingProxy::Proxy
    def destination_uri(rack_request)
      base = Bowtie::Settings['fqdn']['development']
      path = rack_request.path

      URI.join(base, path).to_s
    end
  end
end
