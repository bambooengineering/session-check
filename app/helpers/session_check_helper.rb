require 'devise'

module SessionCheckHelper

  def session_check(options = {})
    locals = {
      session_time: Devise.timeout_in,
      check_every: 10,
      reset_counter_on_ajax: true,
      logged_out_url: '/users/sign_in'
    }.merge options
    render :partial => '/session_check', locals: locals
  end

end
