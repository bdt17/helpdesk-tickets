# Devise's lockable already locks one account after 5 bad passwords, but
# that does nothing against one IP trying a few passwords each across
# many accounts (credential stuffing). This caps sign-in attempts per IP
# on top of that, the same way RegistrationsController caps sign-ups.
#
# Accounts with two-factor on aren't signed in by a correct password
# alone: the password is checked without storing a session, then
# TwoFactorSessionsController asks for the authenticator code.
class SessionsController < Devise::SessionsController
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_user_session_path, alert: "Too many sign-in attempts. Please try again in a few minutes." }

  def create
    user = warden.authenticate!(auth_options.merge(store: false))
    return finish_sign_in(user) unless user.two_factor_enabled?

    session[TwoFactorSessionsController::PENDING_KEY] = {
      "user_id" => user.id,
      "started_at" => Time.current.to_i,
      "remember_me" => params.dig(:user, :remember_me) == "1"
    }
    redirect_to new_two_factor_session_path, status: :see_other
  end

  private

  # What Devise::SessionsController#create does after authenticating.
  # force: true because warden already holds the user (unstored) for this
  # request, and Devise would otherwise skip storing the session.
  def finish_sign_in(user)
    self.resource = user
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, user, force: true)
    respond_with user, location: after_sign_in_path_for(user)
  end
end
