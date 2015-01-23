require 'rubygems'
require 'json'
require 'jekyll'
require 'rack'
require 'rack/streaming_proxy'

module Bowtie
  autoload :DevelopmentProxy,  'bowtie/development_proxy'
  autoload :Settings,          'bowtie/settings'
  autoload :VERSION,           'bowtie/version'
end

require 'bowtie/command'
require 'bowtie/commands/serve'
