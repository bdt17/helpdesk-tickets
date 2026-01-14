class PasswordsController < ApplicationController
  # DELETE THIS LINE: skip_before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  
  def new
    # GET /password/new - Show "Forgot Password" form
  end

  def create
    # POST /password - Send reset email
    email = params[:email]
    user = User.find_by(email: email)

    if user
      user.generate_password_reset_token!
      UserMailer.password_reset(user).deliver_now
      redirect_to root_path, notice: "Password reset instructions sent to #{email}"
    else
      redirect_to new_password_path, alert: "Email not found"
    end
  end

  def edit
    @token = params[:token]
    @user = User.find_by(password_reset_token: @token)
    return redirect_to new_password_path, alert: "Invalid token" unless @user
  end

  def update
    @user = User.find_by(password_reset_token: params[:token])

    if @user && @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset_token!
      redirect_to new_session_path, notice: "Password updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
