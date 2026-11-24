class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Devise handles authentication automatically
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Staff must have two-factor sign-in on; until they do, every page sends
  # them to set it up. Devise's own pages (sign out, password reset) stay
  # reachable.
  before_action :require_two_factor_setup!, unless: :devise_controller?

  private

  def require_two_factor_setup!
    return unless user_signed_in?
    return unless current_user.two_factor_required? && !current_user.two_factor_enabled?

    redirect_to two_factor_setup_path, alert: "Staff accounts need two-factor sign-in. Set it up to continue (takes about a minute)."
  end

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

  # For account management and other admin-only pages.
  def require_admin!
    return if current_user&.admin?

    flash[:alert] = "You are not authorized to perform that action."
    redirect_to root_path
  end
end
