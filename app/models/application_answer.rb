class ApplicationAnswer < ApplicationRecord
  belongs_to :application
  belongs_to :job_question

  validates :job_question_id, uniqueness: { scope: :application_id }
  validate :required_question_has_value

  scope :ordered, -> { joins(:job_question).order("job_questions.position ASC") }

  def question_label
    job_question.label
  end

  def question_kind
    job_question.kind
  end

  private

  def required_question_has_value
    return unless job_question&.required?
    return if value.present?

    errors.add(:value, "is required for '#{job_question.label}'")
  end
end
