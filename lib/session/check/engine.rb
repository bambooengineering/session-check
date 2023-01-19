# frozen_string_literal: true

require 'rails'

module Session
  module Check
    class Engine < ::Rails::Engine
      config.to_prepare do
        ActiveSupport.on_load :action_controller do
          include Session::Check::SessionCheckHelper
          helper_method :session_check
        end
      end
    end
  end
end
