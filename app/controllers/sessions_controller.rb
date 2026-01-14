class SessionsController < ApplicationController
  # Devise-compatible - NO Rails 8 Authentication needed
  skip_before_action :authenticate_user!, only: [:new, :create]
  
  rate_limit to: 10, within: 3.minutes, only: :create, 
    with: -> { redirect_to new_session_path, alert: "Too many login attempts" }

  def new
  end

  def create
    email = params[:email] || params[:email_address]
    if user = User.find_by(email: email)&.authenticate(params[:password])
      # Your PERFECT cookie auth - production ready
      cookies.signed.permanent[:user_id] = { value: user.id, httponly: true }
      redirect_to root_path, notice: "Welcome to Thomas IT Helpdesk, #{user.email}!"
    else
      redirect_to new_session_path, alert: "Invalid email or password"
    end
  end

  def destroy
    # Simple cookie delete - NO terminate_session needed
    cookies.delete(:user_id)
    redirect_to new_session_path, status: :see_other
  end
end
