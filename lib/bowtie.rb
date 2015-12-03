require 'rubygems'
require 'json'
require 'jekyll'
require 'rack'
require 'rack/proxy'
require 'restclient'

module Bowtie
  module Middleware
    autoload :Proxy       , 'bowtie/middleware/proxy'
    autoload :Static      , 'bowtie/middleware/static'
    autoload :Rewrite     , 'bowtie/middleware/rewrite'
    autoload :PolicyCheck , 'bowtie/middleware/policy_check'
    autoload :Session     , 'bowtie/middleware/session'
  end

  autoload :Settings,  'bowtie/settings'
  autoload :VERSION,   'bowtie/version'
end

require 'bowtie/command'
require 'bowtie/commands/serve'
require 'bowtie/errors'
