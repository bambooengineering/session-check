# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)

require 'session/check/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'session-check'
  s.version = Session::Check::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.homepage = 'https://github.com/bambooengineering/session-check'
  s.summary = 'A gem for JS clients to check if their session has expired.'
  s.license = 'MIT'

  s.files = Dir["{app,lib,config}/**/*"] + ["README.md"]
  s.require_paths = ['lib']

  s.add_dependency 'rails', '>= 5.0'
  s.add_dependency 'devise'
  s.add_development_dependency 'combustion'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec-rails', '~> 5.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'timecop'
end
