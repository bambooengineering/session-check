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
          # Fetch the Warden user directly, with `run_callbacks: false`, instead of calling
          # `controller.current_user`. Devise's Timeoutable module hooks into Warden's
          # `after_set_user` callback (triggered by `current_user`/`authenticate`) and, when the
          # session has actually timed out, signs the user out and does
          # `throw :warden, message: :timeout`. Since this endpoint is JSON-only, that throw is
          # handled by Warden's failure app as a 401 response rather than the plain
          # `{ exists: false }` payload this proc is supposed to return, so callers ended up
          # seeing a 401 instead of a graceful "session no longer active" result. Skipping
          # callbacks avoids triggering that sign-out/401 side effect on every check.
          warden = begin
            controller.request.env['warden']
          rescue NoMethodError
            nil
          end
          user = warden&.user(scope: :user, run_callbacks: false)
          if user
            expires_in = Session::Check::Devise.expires_in(controller.session)
            { exists: expires_in.positive?, expires_in: expires_in }
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
