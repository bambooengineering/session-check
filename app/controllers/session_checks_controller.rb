class SessionChecksController < ActionController::Base

  skip_authorization_check if defined?(CanCan)
  session :off # Don't keep the session alive

  # Find it there is a session, and if it has any warden information. If so, the user is logged in.
  def time_to_session_expiry
    sid = request.cookies['_session_id']
    sess = Redis.current.get("www_session:#{sid}")
    render json: {session_exists: (sess && sess.include?('warden'))}
  end
end
