# frozen_string_literal: true

module Session
  module Check
    class SessionChecksController < ActionController::Base
      skip_authorization_check if defined?(CanCan)

      prepend_before_action :dont_update_request_time

      # Find it there is a session, and if it has any warden information. If so, the user is logged in.
      def time_to_session_expiry
        session_exists = false
        session_expires_in = 0
        if current_user
          session_exists = true
          # This calculates how many seconds there are until they are logged out
          session_expires_in = calculate_session_expires_in
        end
        render json: { session_exists: session_exists, session_expires_in: session_expires_in }
      end

      # This ensures this request ping doesn't update their last access time.
      private def dont_update_request_time
        request.env['devise.skip_trackable'] = true
      end

      private def calculate_session_expires_in
        User.timeout_in -
          Time.now.utc.to_i.seconds +
          SessionChecksController.time_of_last_warden_request(session).to_i.seconds
      rescue => _e
        1000000.seconds
      end

      class << self
        def time_of_last_warden_request(session)
          session['warden.user.user.session']['last_request_at']
        rescue => _e
          Time.zone.now
        end
      end
    end
  end
end
