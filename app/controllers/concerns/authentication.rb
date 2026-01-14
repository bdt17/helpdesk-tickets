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

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def user_signed_in?
    !current_user.nil?
  end
  helper_method :user_signed_in?
end
