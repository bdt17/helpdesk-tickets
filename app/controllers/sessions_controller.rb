class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

def create
  email = params[:email] || params[:email_address]
  if user = User.find_by(email: email)&.authenticate(params[:password])
    # BYPASS complex session system - use simple cookie
    cookies.signed.permanent[:user_id] = { value: user.id, httponly: true }
    redirect_to root_path, notice: "Welcome to Thomas IT Helpdesk, #{user.email}!"
  else
    redirect_to new_session_path, alert: "Invalid email or password"
  end
end


  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
