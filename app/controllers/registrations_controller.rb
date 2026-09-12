# Public self-service sign up. This is the ONLY way an account gets created
# without an admin provisioning it directly, so it must never be able to
# produce anything but a client account — role is hardcoded below and never
# read from params, regardless of what Devise's own param sanitizer permits.
class RegistrationsController < Devise::RegistrationsController
  # By IP, not email - an unauthenticated signup form has no other
  # identity to rate-limit by, and the point is to blunt a bot hammering
  # this endpoint, not to inconvenience one real person who mistypes a
  # password a few times (that's #create, not #update, so it only ever
  # limits how many new accounts one IP can produce, never a legitimate
  # user's own sign-in attempts).
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_user_registration_path, alert: "Too many signup attempts. Please try again in a bit." }

  # Devise's own #create yields the just-built resource to this block
  # after attempting to save it - only send the welcome email if it
  # actually persisted, not on a validation failure that re-renders the
  # sign-up form.
  def create
    super do |resource|
      UserMailer.welcome(resource).deliver_later if resource.persisted?
    end
  end

  private

  def build_resource(hash = {})
    super(hash)
    resource.role = :client
  end

  def after_sign_up_path_for(resource)
    new_ticket_path
  end

  # Devise's default already redirects home after a password/email change;
  # send everyone back to their own dashboard instead, whatever their role.
  def after_update_path_for(resource)
    dashboard_path
  end
end
