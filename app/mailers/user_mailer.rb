class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = edit_password_url(token: user.password_reset_token)
    mail(to: user.email, subject: "Thomas IT Helpdesk - Reset Your Password")
  end
end
