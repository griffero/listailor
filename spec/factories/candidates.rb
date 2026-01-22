FactoryBot.define do
  factory :candidate do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    sequence(:email) { |n| "candidate#{n}@example.com" }
    phone { Faker::PhoneNumber.phone_number }
    linkedin_url { "https://linkedin.com/in/#{Faker::Internet.username}" }
  end
end
