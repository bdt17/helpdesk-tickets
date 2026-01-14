class PasswordsController < ApplicationController
  def new
    # GET /password/new - Forgot password form
  end

  def create
    # POST /password - Send reset email
    email = params[:email]
    user = User.find_by(email: email)

    if user
      user.generate_password_reset_token!
      UserMailer.password_reset(user).deliver_now
      redirect_to root_path, notice: "Reset instructions sent"
    else
      redirect_to new_password_path, alert: "Email not found"
    end
  end

  def edit
    # GET /password/edit?token=abc123
    @token = params[:token]
    @user = User.find_by(password_reset_token: @token)
    redirect_to new_password_path, alert: "Invalid token" unless @user
  end

  def update
    # PATCH /password
    @user = User.find_by(password_reset_token: params[:token])
    if @user && @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset_token!
      redirect_to new_session_path, notice: "Password updated"
    else
      render :edit
    end
  end
end
