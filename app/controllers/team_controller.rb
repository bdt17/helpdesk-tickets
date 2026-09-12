# Lets an organization's owner add or remove seats on their subscription
# (Phase 12). Invited members are created immediately (so they show up as
# a seat right away) with a random, unknown password and pointed at
# Devise's password-reset flow to set their own — nobody but the invitee
# ever sees a real password for the account.
class TeamController < ApplicationController
  before_action :authenticate_user!
  before_action :require_org_owner!

  # By current_user, not IP - this is authenticated and already
  # owner-only, so the threat here isn't an anonymous bot but a
  # compromised or careless owner account mass-creating seats/sending
  # invite emails. #destroy isn't limited - removing a teammate doesn't
  # create anything or send mail, so there's nothing to blunt.
  rate_limit to: 10, within: 1.hour, only: :create, by: -> { current_user.id },
             with: -> { redirect_to team_path, alert: "Too many invites sent. Please try again in a bit." }

  def index
    @organization = current_user.organization
    @members = @organization.users.order(:email)
  end

  def create
    organization = current_user.organization
    email = params[:email].to_s.strip.downcase

    unless organization.seats_available?
      plan_name = organization.plan_definition&.name || "current"
      return redirect_to team_path, alert: "The #{plan_name} plan allows up to #{organization.max_seats} seats - remove a teammate or upgrade to invite more."
    end
    if email.blank?
      return redirect_to team_path, alert: "Enter an email address."
    end
    if User.exists?(email: email)
      return redirect_to team_path, alert: "That email already has an account."
    end

    temp_password = SecureRandom.hex(16)
    member = User.new(
      email: email, password: temp_password, password_confirmation: temp_password,
      role: :client, organization: organization, org_role: "member"
    )

    if member.save
      member.send_reset_password_instructions
      redirect_to team_path, notice: "Invited #{email} — they'll get an email to set their password."
    else
      redirect_to team_path, alert: member.errors.full_messages.to_sentence
    end
  end

  def destroy
    member = current_user.organization.users.find(params[:id])

    if member == current_user
      redirect_to team_path, alert: "You can't remove yourself from the team."
    else
      member.update!(organization: nil, org_role: nil)
      redirect_to team_path, notice: "Removed #{member.email} from the team."
    end
  end

  private

  def require_org_owner!
    return if current_user.client? && current_user.org_owner?

    redirect_to billing_path, alert: "Only the account owner can manage the team."
  end
end
