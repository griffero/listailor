FactoryBot.define do
  factory :job_posting do
    sequence(:title) { |n| "Job #{n}" }
    sequence(:slug) { |n| "job-#{n}" }
    description { "Job description" }
    department { "Engineering" }
    location { "Remote" }

    trait :published do
      published_at { Time.current }
    end

    trait :draft do
      published_at { nil }
    end
  end
end
