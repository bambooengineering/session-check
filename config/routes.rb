# frozen_string_literal: true

# Draw directly into the host application's routes (rather than
# `Session::Check::Engine.routes.draw`) so the endpoint is auto-wired for any
# consuming app without requiring an explicit `mount Session::Check::Engine`,
# matching the README usage (`<%= session_check %>` only).
Rails.application.routes.draw do
  get 'session_check/time_to_session_expiry',
      to: 'session/check/session_checks#time_to_session_expiry',
      format: :json,
      defaults: { format: :json }
end
