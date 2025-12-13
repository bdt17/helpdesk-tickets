puts "Creating test accounts..."

User.create!(
  email: "tech@thomasit.com",
  password: "password123",
  password_confirmation: "password123",
  role: "tech"
)

User.create!(
  email: "client@thomasit.com", 
  password: "password123",
  password_confirmation: "password123",
  role: "client"
)

puts "Test accounts created!"
puts "TECH: tech@thomasit.com / password123"
puts "CLIENT: client@thomasit.com / password123"
