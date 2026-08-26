class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Devise handles authentication automatically
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform that action."
    redirect_back fallback_location: root_path
  end

  # Gate for internal-only pages (staff rosters, reports, etc.) now that
  # self-service sign up lets outside clients hold real accounts.
  def require_staff!
    return if current_user&.agent? || current_user&.admin?

    flash[:alert] = "You are not authorized to perform that action."
    redirect_to root_path
  end
end
