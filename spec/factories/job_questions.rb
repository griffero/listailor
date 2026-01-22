FactoryBot.define do
  factory :job_question do
    association :job_posting
    sequence(:label) { |n| "Question #{n}" }
    kind { "long_text" }
    required { false }
    sequence(:position) { |n| n }
  end
end
