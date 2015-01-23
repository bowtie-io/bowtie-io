module Bowtie
  module Commands
    class Serve < Command
      class << self
        def init_with_program(prog)
          command = Jekyll::Commands::Serve.init_with_program(prog)
          command.description 'Development server'
          command.actions.clear

          command.action do |args, options|
            options['serving'] = true
            options['watch'] = true unless options.key?('watch')

            Jekyll::Commands::Build.process(options)
            Bowtie::Commands::Serve.process(options)
          end
        end

        def process(options)
          Rack::Server.start(app: application(options),
                             Port: options['port'],
                             Host: options['host'],
                             daemonize: options['detach'])
        end

        private
        def application(options)
          options = Jekyll.configuration(options)

          Rack::Builder.new do
            use Rack::CommonLogger
            use Rack::ShowExceptions

            # User management provided by BowTie /users/*
            map '/users' do
              use Bowtie::DevelopmentProxy
            end

            # Bowtie APIs available at /bowtie/*
            map '/bowtie' do
              use Bowtie::DevelopmentProxy
            end

            # Static file server
            use Rack::Static, urls: [''], root: options['destination'], index: 'index.html'

            # 404 handler
            run Proc.new { |env| [404, {"Content-Type" => "text/html"}, File.read(File.join(options['destination'], '404.html'))] }
          end
        end
      end
    end
  end
end
