class SessionsController < ApplicationController
  def new
    # GET /login - Show login form
  end

  def create
    # POST /login - Process login
    email = params[:email]
    password = params[:password]
    user = User.find_by(email: email)
    
    if user && user.authenticate(password)
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email/password"
      render :new
    end
  end

  def destroy
    # DELETE /logout - Logout
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out"
  end
end
