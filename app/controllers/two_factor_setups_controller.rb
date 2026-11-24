# Account > Two-factor: staff set up an authenticator app here (they're
# sent here until they do - see ApplicationController#require_two_factor_setup!)
# and can make fresh backup codes. Turning 2FA off isn't offered: it's
# required for staff. A lost phone is an admin reset at /admin/users.
class TwoFactorSetupsController < ApplicationController
  SETUP_SECRET_KEY = :two_factor_setup_secret

  before_action :authenticate_user!
  skip_before_action :require_two_factor_setup!
  before_action :require_two_factor_eligible!
  # The setup key and backup codes shouldn't sit in the browser cache.
  before_action { response.headers["Cache-Control"] = "no-store" }

  def show
    return if current_user.two_factor_enabled?

    @secret = (session[SETUP_SECRET_KEY] ||= User.generate_otp_secret)
    svg = RQRCode::QRCode.new(current_user.otp_provisioning_uri(@secret))
                         .as_svg(module_size: 4, standalone: true, use_path: true, viewbox: true)
    # As an <img> data URI (CSP allows data: images), so no raw markup goes into the page.
    @qr_data_uri = "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  def create
    return redirect_to two_factor_setup_path if current_user.two_factor_enabled?

    secret = session[SETUP_SECRET_KEY]
    @backup_codes = secret && current_user.enable_two_factor!(secret, params[:code])
    if @backup_codes
      session.delete(SETUP_SECRET_KEY)
      flash.now[:notice] = "Two-factor sign-in is on."
      render :backup_codes
    else
      redirect_to two_factor_setup_path, alert: "That code didn't match. Check your phone's time is automatic and try the newest code."
    end
  end

  # New backup codes (the old ones stop working). Needs a current code so
  # a hijacked session alone can't mint fresh codes.
  def backup_codes
    unless current_user.two_factor_enabled? && current_user.verify_second_factor!(params[:code]) == :otp
      return redirect_to two_factor_setup_path, alert: "Enter a current code from your authenticator app."
    end

    @backup_codes = current_user.regenerate_backup_codes!
    flash.now[:notice] = "New backup codes made. The old ones no longer work."
    render :backup_codes
  end

  private

  def require_two_factor_eligible!
    return if current_user.two_factor_required? || current_user.two_factor_enabled?

    redirect_to root_path, alert: "Two-factor sign-in is only for staff accounts right now."
  end
end
