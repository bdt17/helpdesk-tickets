# Account-lifecycle emails, as opposed to TicketMailer's per-ticket ones.
class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user

    mail(to: user.email, subject: "Welcome to Thomas IT Helpdesk")
  end

  # Replaces Devise's generic "Reset password instructions" email for a
  # brand-new teammate, who has never had a password to reset.
  def team_invite(user, inviter, raw_token)
    @user = user
    @inviter = inviter
    @organization = user.organization
    @set_password_url = edit_user_password_url(reset_password_token: raw_token, invite: 1)
    @valid_for = User::INVITE_LINK_VALIDITY.inspect

    mail(to: user.email, subject: "#{inviter.email} invited you to #{@organization.name} on Thomas IT Helpdesk")
  end
end
