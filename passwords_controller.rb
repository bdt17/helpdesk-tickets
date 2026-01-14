class PasswordsController < ApplicationController
#  skip_before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  
  def new
    # GET /password/new - Forgot password form
  end

  def create
    # POST /password - Send reset email
    email = params[:email]
    user = User.find_by(email: email.downcase)
    
    if user
      # Simple token generation (no mailer needed for MVP)
      token = SecureRandom.hex(20)
      user.update_column(:password_reset_token, token)
      user.update_column(:password_reset_sent_at, Time.current)
      
      flash[:notice] = "Check your email for reset instructions (#{email})"
    else
      flash[:alert] = "Email not found"
    end
    
    redirect_to new_password_path
  end

  def edit
    # GET /password/edit?token=abc123 - Reset form
    @token = params[:token]
    @user = User.find_by(password_reset_token: @token)
    
    unless @user && @user.password_reset_sent_at > 1.hour.ago
      flash[:alert] = "Invalid or expired reset link"
      redirect_to new_password_path
    end
  end

  def update
    # PATCH /password - Update password
    @user = User.find_by(password_reset_token: params[:token])
    
    if @user && @user.password_reset_sent_at > 1.hour.ago &&
       @user.update(password: params[:password], password_confirmation: params[:password])
      
      @user.update_column(:password_reset_token, nil)
      @user.update_column(:password_reset_sent_at, nil)
      flash[:notice] = "Password updated successfully!"
      redirect_to new_session_path
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
