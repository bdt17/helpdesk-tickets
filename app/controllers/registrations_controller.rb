# Public self-service sign up. This is the ONLY way an account gets created
# without an admin provisioning it directly, so it must never be able to
# produce anything but a client account — role is hardcoded below and never
# read from params, regardless of what Devise's own param sanitizer permits.
class RegistrationsController < Devise::RegistrationsController
  private

  def build_resource(hash = {})
    super(hash)
    resource.role = :client
  end

  def after_sign_up_path_for(resource)
    new_ticket_path
  end
end
