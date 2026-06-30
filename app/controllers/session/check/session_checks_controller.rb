# frozen_string_literal: true

module Session
  module Check
    class SessionChecksController < ActionController::Base
      skip_authorization_check if defined?(CanCan)

      prepend_before_action :dont_update_request_time

      def time_to_session_expiry
        result = Session::Check.configuration.call_session_active_proc(self)
        render json: { session_exists: !!result[:exists], session_expires_in: result[:expires_in].to_i }
      end

      # This ensures this request ping doesn't update their last access time.
      private def dont_update_request_time
        request.env['devise.skip_trackable'] = true
      end
    end
  end
end
