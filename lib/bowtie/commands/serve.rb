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
          Bowtie::Middleware::PolicyCheck.watch!

          Rack::Server.start(app: application(options),
                             Port: options['port'] || 4000,
                             Host: options['host'],
                             daemonize: options['detach'])
        end

        private
        def application(options)
          options = Jekyll.configuration(options)

          Rack::Builder.new do
            use Rack::CommonLogger
            use Rack::ShowExceptions
            use Rack::Session::Cookie, key: 'client.session',
              secret: '_bowtie_client_local'

            use Bowtie::Middleware::Rewrite, options

            # User management provided by BowTie /users/*
            map '/users' do
              use Bowtie::Middleware::Session
              use Bowtie::Middleware::Proxy
            end

            # Bowtie APIs available at /bowtie/*
            map '/bowtie' do
              use Bowtie::Middleware::Proxy
            end

            # Policy checks
            use Bowtie::Middleware::PolicyCheck

            # Static file server
            use Bowtie::Middleware::Static, urls: [''],
              root: options['destination'],
              index: 'index.html'

            # Backend API proxy through BowTie
            run Bowtie::Middleware::Proxy.new
          end
        end
      end
    end
  end
end
