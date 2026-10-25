module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # active_for_authentication? so a disabled or locked account can't keep
      # a socket open on a session cookie it was issued before being disabled.
      verified_user = env["warden"].user
      if verified_user&.active_for_authentication?
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
