# Account-lifecycle emails, as opposed to TicketMailer's per-ticket ones.
class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user

    mail(to: user.email, subject: "Welcome to Thomas IT Helpdesk")
  end
end
