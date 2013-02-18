require 'rails'

module Session
  module Check
    class Engine < ::Rails::Engine
      initializer "session-check.loader" do
        ActiveSupport.on_load(:action_controller) do
          include SessionCheckHelper
          helper_method :session_check_js
        end
      end
    end
  end
end

