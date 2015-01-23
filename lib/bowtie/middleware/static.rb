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

      if status != 200
        status, response, headers = @app.call(env)
        status = status.to_i

        if status == 404
          env['PATH_INFO'] = '/404.html'
        elsif status == 403
          env['PATH_INFO'] = '/403.html'
        elsif status.between?(500, 599)
          env['PATH_INFO'] = '/500.html'
        elsif status.between?(400, 499)
          env['PATH_INFO'] = '/400.html'
        else
          return [status, response, headers]
        end

        return @rack_static.call(env)
      else
        [status, response, headers]
      end
    end
  end
end
