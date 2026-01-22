FactoryBot.define do
  factory :application do
    association :job_posting, :published
    association :candidate
    source { "test" }

    trait :with_stage do
      after(:build) do |application|
        application.current_stage ||= PipelineStage.first || create(:pipeline_stage)
      end
    end
  end
end
