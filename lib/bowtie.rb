require 'rubygems'
require 'json'
require 'jekyll'
require 'rack'
require 'rack/streaming_proxy'

module Bowtie
  module Middleware
    autoload :Proxy,   'bowtie/middleware/proxy'
    autoload :Static,  'bowtie/middleware/static'
  end

  autoload :Settings,  'bowtie/settings'
  autoload :VERSION,   'bowtie/version'
end

require 'bowtie/command'
require 'bowtie/commands/serve'
