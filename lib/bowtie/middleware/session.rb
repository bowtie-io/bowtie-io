module Bowtie::Middleware
  class Session
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      if headers['X-Bowtie-Client-Session']
        rr = Rack::Request.new(env)

        open "/Users/james/Documents/src/bowtie-lite/tmp.txt", "a" do |f|
          f << "Path: #{rr.path} / Headers: #{headers.inspect}\n"
        end


        env['rack.session']['user'] = JSON.parse(headers['X-Bowtie-Client-Session'])
      end

      [status, headers, response]
    end
  end
end
