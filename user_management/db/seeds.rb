# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.create(name: "user1", email: "user1@gmail.com", password: "user1")
User.create(name: "user2", email: "user2@gmail.com", password: "user2")
User.create(name: "user3", email: "user3@gmail.com", password: "user3")

Product.create(name: "Basic", unit_amount: 100, currency: "INR")
Product.create(name: "Premium", unit_amount: 200, currency: "INR")
Product.create(name: "Enterprise", unit_amount: 300, currency: "INR")