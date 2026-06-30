# frozen_string_literal: true

require 'devise'

module Session
  module Check
    class Configuration
      # Proc used to determine session state. Called with the controller/helper context as its
      # sole argument. Must return a Hash: { exists: Boolean, expires_in: Integer (seconds) }
      #
      # Override to customise session detection for non-Devise sessions.
      attr_accessor :session_active_proc, :logged_out_url, :check_every_s

      def initialize
        @logged_out_url = '/users/sign_in'
        @check_every_s = 10
        @session_active_proc = ->(controller) {
          user = begin
            controller.current_user
          rescue NoMethodError
            nil
          end
          if user
            expires_in = Session::Check::Devise.expires_in(controller.session)
            { exists: true, expires_in: expires_in }
          else
            { exists: false, expires_in: 0 }
          end
        }
      end

      def call_session_active_proc(context)
        result = session_active_proc.call(context)
        unless result.is_a?(Hash)
          raise ArgumentError,
            "session_active_proc must return a Hash with :exists and :expires_in keys, got #{result.class}"
        end
        normalized = result.transform_keys(&:to_sym)
        { exists: normalized[:exists], expires_in: normalized[:expires_in] }
      end
    end
  end
end
