# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bowtie/version'

Gem::Specification.new do |s|
  s.name        = 'bowtie-io'
  s.version     = Bowtie::VERSION
  s.authors     = ['James Kassemi']
  s.email       = ['james@seedworthy.com']
  s.description = 'Client interface to the BowTie frontend development service'
  s.summary     = 'Contains command line interface for interacting with BowTie Projects and tools for local development'
  s.homepage    = 'https://bowtie.io'
  s.license     = 'MIT'

  all_files       = `git ls-files -z`.split("\x0")
  s.files         = all_files.grep(%r{^(bin|lib)/})
  s.executables   = all_files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  # Base static content generator and command utility (MIT)
  s.add_runtime_dependency 'jekyll', '~> 3.0'

  # Web server interface wrapper (MIT)
  s.add_runtime_dependency 'rack', '~> 1.6'

  # Proxy necessary requests to BowTie Project development site
  s.add_runtime_dependency 'rack-proxy', '~> 0.5.17'

  # Request information for user info and profiles from bowtie API
  s.add_runtime_dependency 'rest-client', '~> 1.8.0'

  # scss compilation requires more recent version of sass
  s.add_runtime_dependency 'sass', '~> 3.4'
end
