# Create a demo user for testing
User.find_or_create_by(email: "demo@example.com") do |user|
  user.name = "Demo User"
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "✅ Seed complete! Demo user: demo@example.com / password123"
