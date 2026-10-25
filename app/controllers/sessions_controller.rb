# Devise's lockable already locks one account after 5 bad passwords, but
# that does nothing against one IP trying a few passwords each across
# many accounts (credential stuffing). This caps sign-in attempts per IP
# on top of that, the same way RegistrationsController caps sign-ups.
class SessionsController < Devise::SessionsController
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_user_session_path, alert: "Too many sign-in attempts. Please try again in a few minutes." }
end
