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

employee = User.find_by(email: "employee@thomasit.com")
agent = User.find_by(email: "agent@thomasit.com")

[
  {
    title: "Laptop won't power on",
    description: "Held down the power button for 30s, still nothing. Battery light is off too.",
    status: "open",
    priority: "high",
    category: "hardware",
    user: employee
  },
  {
    title: "Can't connect to office VPN",
    description: "VPN client fails to connect with a timeout error since this morning.",
    status: "in_progress",
    priority: "medium",
    category: "network",
    user: employee,
    assignee: agent
  },
  {
    title: "Need access to shared drive",
    description: "Requesting read/write access to the Finance shared drive for the new hire.",
    status: "resolved",
    priority: "low",
    category: "access",
    user: employee,
    assignee: agent
  }
].each do |attrs|
  Ticket.find_or_create_by!(title: attrs[:title]) { |t| t.assign_attributes(attrs) }
end
