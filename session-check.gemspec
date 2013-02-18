$:.push File.expand_path("../lib", __FILE__)

require 'session/check/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'session-check'
  s.version = Session::Check::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.homepage = 'https://github.com/firstbanco/session-check'
  s.summary = 'A gem for JS clients to check if their session has expired.'

  s.files = Dir["{lib,config}/**/*"] + ["README.md"]
  s.require_paths = ['lib']

  s.add_dependency 'rails'
end
