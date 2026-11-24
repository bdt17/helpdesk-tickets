# Second step of signing in for accounts with two-factor on (see
# SessionsController#create): the password was right, now the 6-digit
# authenticator code or a backup code. A wrong code counts as a failed
# sign-in for Devise's lockable, so the account locks after the same 5
# failures as wrong passwords.
class TwoFactorSessionsController < ApplicationController
  PENDING_KEY = :two_factor_pending
  PENDING_TTL = 5.minutes

  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_user_session_path, alert: "Too many sign-in attempts. Please try again in a few minutes." }

  skip_before_action :require_two_factor_setup!
  before_action :load_pending_user

  def new
  end

  def create
    result = @user.verify_second_factor!(params[:code])
    unless result
      record_failure
      return if performed?

      flash.now[:alert] = "That code didn't work. Try the newest code from your app."
      return render :new, status: :unprocessable_entity
    end

    remember = session[PENDING_KEY]["remember_me"]
    session.delete(PENDING_KEY)
    @user.remember_me = remember
    @user.second_factor_passed = true
    sign_in(:user, @user)

    notice = "Signed in successfully."
    if result == :backup_code
      notice += " You used a backup code - #{@user.backup_codes_remaining} left."
      notice += " Make new ones from Account > Two-factor." if @user.backup_codes_remaining <= 3
    end
    redirect_to after_sign_in_path_for(@user), notice: notice, status: :see_other
  end

  private

  def load_pending_user
    pending = session[PENDING_KEY]
    @user = User.find_by(id: pending["user_id"]) if pending.is_a?(Hash)

    if @user.nil? || pending["started_at"].to_i < PENDING_TTL.ago.to_i || !@user.active_for_authentication?
      session.delete(PENDING_KEY)
      redirect_to new_user_session_path, alert: "Please sign in again."
    end
  end

  def record_failure
    return unless @user.register_failed_second_factor!

    session.delete(PENDING_KEY)
    redirect_to new_user_session_path, alert: "Too many wrong codes. Your account is locked - check your email or try again in an hour."
  end
end
