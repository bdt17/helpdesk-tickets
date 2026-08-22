{
  "employee@thomasit.com" => "employee",
  "agent@thomasit.com" => "agent",
  "admin@thomasit.com" => "admin"
}.each do |email, role|
  User.find_or_create_by!(email: email) do |user|
    user.password = "changeme123"
    user.password_confirmation = "changeme123"
    user.role = role
  end
end
