require 'rails'

module Session
  module Check
    class Engine < ::Rails::Engine
      initializer "session-check.loader" do
      end
    end
  end
end

