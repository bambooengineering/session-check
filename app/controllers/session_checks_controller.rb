class SessionChecksController < ActionController::Base

  skip_authorization_check if defined?(CanCan)

  prepend_before_filter :dont_update_request_time

  # Find it there is a session, and if it has any warden information. If so, the user is logged in.
  def time_to_session_expiry
    session_exists = false
    session_expires_in = 0
    if current_user
      session_exists = true
      # This calculates how many seconds there are until they are logged out
      session_expires_in = User.timeout_in - Time.now.utc.to_i + session['warden.user.user.session']['last_request_at'].to_i rescue 1000000
    end
    render json: {session_exists: session_exists, session_expires_in: session_expires_in}
  end

  # This ensures this requeust ping doesn't update their last access time.
  def dont_update_request_time
    env['devise.skip_trackable'] = true
  end
end
