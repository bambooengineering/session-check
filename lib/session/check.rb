require 'rails'

module Session
  module Check
    class Engine < ::Rails::Engine
      initializer "session-check.loader" do
        # Loads the helper
      end
    end
  end
end

