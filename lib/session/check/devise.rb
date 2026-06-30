# frozen_string_literal: true

module Session
  module Check
    module Devise
      def self.expires_in(session)
        last_request_at = begin
          session['warden.user.user.session']['last_request_at'].to_i
        rescue NoMethodError, TypeError
          Time.now.utc.to_i
        end
        remaining = ::Devise.timeout_in.to_i - (Time.now.utc.to_i - last_request_at)
        [remaining, 0].max
      end
    end
  end
end
