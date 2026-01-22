FactoryBot.define do
  factory :pipeline_stage do
    sequence(:name) { |n| "Stage #{n}" }
    sequence(:position) { |n| n }
    kind { "active" }

    trait :hired do
      name { "Hired" }
      kind { "hired" }
    end

    trait :rejected do
      name { "Rejected" }
      kind { "rejected" }
    end
  end
end
