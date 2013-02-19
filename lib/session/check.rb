require 'rails'

module Session
  module Check
    class Engine < ::Rails::Engine
      initializer "session-check.loader" do
        ActiveSupport.on_load :action_controller do
          helper SessionCheckHelper
        end
      end
    end
  end
end

