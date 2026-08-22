class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Devise handles authentication automatically
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform that action."
    redirect_back fallback_location: root_path
  end
end
