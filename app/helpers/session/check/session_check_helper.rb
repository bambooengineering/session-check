# frozen_string_literal: true

module Session
  module Check
    module SessionCheckHelper
      def session_check(options = {})
        result = Session::Check.configuration.call_session_active_proc(self)
        session_active = !!result[:exists]
        session_time = result[:expires_in].to_i

        locals = {
          session_time: session_time,
          check_every_s: Session::Check.configuration.check_every_s,
          reset_counter_on_ajax: true,
          logged_out_url: Session::Check.configuration.logged_out_url,
          session_active: session_active
        }.merge(options)

        ActionController::Base.render(partial: '/session_check', locals: locals)
      end
    end
  end
end
