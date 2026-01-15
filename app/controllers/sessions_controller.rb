class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:email]&.downcase)
    if user && BCrypt::Password.new(user.password_digest) == params[:password]
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome to Thomas IT Helpdesk!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out!"
  end
end
