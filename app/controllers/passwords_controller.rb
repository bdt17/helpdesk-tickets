# Every reset request sends a real email, so without a cap one IP could
# flood any address (a client's, an agent's) with reset mail. Only
# #create sends mail; #update (actually setting the new password) needs
# a valid token already and isn't limited.
class PasswordsController < Devise::PasswordsController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_user_password_path, alert: "Too many password reset requests. Please try again in a bit." }

  protected

  # Devise signs people in straight after a reset. With two-factor on,
  # that would skip the code (anyone with access to the inbox could get
  # in), so those accounts go back to the normal sign-in instead.
  def sign_in_after_reset_password?
    super && !resource.two_factor_enabled?
  end
end
