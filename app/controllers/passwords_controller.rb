# Every reset request sends a real email, so without a cap one IP could
# flood any address (a client's, an agent's) with reset mail. Only
# #create sends mail; #update (actually setting the new password) needs
# a valid token already and isn't limited.
class PasswordsController < Devise::PasswordsController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_user_password_path, alert: "Too many password reset requests. Please try again in a bit." }
end
