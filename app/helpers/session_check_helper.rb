require 'devise'

module SessionCheckHelper

  def session_check
    "<script>
    (function(){
      var session_time_left = #{Devise.timeout_in};
      var session_check = function(){
      session_time_left = session_time_left - 10;
      if (session_time_left < 0){
        window.location = '/users/sign_in';
      }
          setTimeout(session_check, 10000);
      }
      setTimeout(session_check, 10000);
        $.ajaxSetup({
          complete: function(xhr) {
            session_time_left = #{Devise.timeout_in};
          }
      });
    }());
    </script>".html_safe
  end

end
