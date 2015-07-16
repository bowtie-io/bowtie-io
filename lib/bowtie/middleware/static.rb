module Bowtie::Middleware
  class Static
    def initialize(app, options)
      @app         = app
      @options     = options
      @rack_static = Rack::Static.new(app, options)
    end

    def call(env)
      status, response, headers = @rack_static.call(env)
      status = status.to_i

      if status != 200 && !status.between?(300, 399)
        return @app.call(env)
      else
        [status, response, headers]
      end
    end
  end
end
