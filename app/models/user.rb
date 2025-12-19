def create
  email = params[:email] || params[:email_address]
  if user = User.find_by(email: email)&.authenticate(params[:password])
    cookies.signed.permanent[:user_id] = { value: user.id, httponly: true }
    redirect_to root_path, notice: "Welcome to Thomas IT Helpdesk, #{user.email}!"
  else
    redirect_to new_session_path, alert: "Invalid email or password"
  end
end
