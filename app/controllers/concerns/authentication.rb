module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    unless current_user
      redirect_to new_session_path, alert: "Please log in"
    end
  end
end
