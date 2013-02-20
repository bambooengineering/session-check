Rails.application.routes.draw do
  get 'session_check/time_to_session_expiry', to: 'session_checks#time_to_session_expiry'
end
