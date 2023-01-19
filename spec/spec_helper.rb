# frozen_string_literal: true

Bundler.require :default, :test

require "rails/all"
require "combustion"
require "pry-byebug"
require "timecop"

Combustion.initialize! :active_record
Combustion::Database.setup

ActionController::Base.class_eval do
  def current_user
    User.new
  end
end

class SomeController < ActionController::Base
end

require "rspec/rails"
