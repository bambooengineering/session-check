require 'devise'

module SessionCheckHelper

  def session_check
    render :partial => '/session_check', locals: {session_time: Devise.timeout_in}
  end

end
