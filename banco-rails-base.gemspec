$:.push File.expand_path("../lib", __FILE__)

require 'session/check/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'session-check'
  s.version = Session::Check::VERSION
  s.authors = ['Banco Dev']
  s.email = ['dev@firstbanco.com']
  s.summary = 'Rails Engine for clients to check if their session has expired'

  s.files = Dir["{lib,config}/**/*"] + ["README.md"]
  s.require_paths = ['lib']

  s.add_dependency 'rails'
end
