class ApplicationAnswer < ApplicationRecord
  belongs_to :application
  belongs_to :job_question, optional: true
  belongs_to :global_question, optional: true

  validates :job_question_id, uniqueness: { scope: :application_id }, allow_nil: true
  validates :global_question_id, uniqueness: { scope: :application_id }, allow_nil: true
  validate :has_exactly_one_question
  validate :required_question_has_value

  scope :ordered, -> { order(created_at: :asc) }
  scope :for_job_questions, -> { where.not(job_question_id: nil) }
  scope :for_global_questions, -> { where.not(global_question_id: nil) }

  def question
    job_question || global_question
  end

  def question_label
    question&.label
  end

  def question_kind
    question&.kind
  end

  private

  def has_exactly_one_question
    if job_question_id.nil? && global_question_id.nil?
      errors.add(:base, "must have either a job_question or global_question")
    elsif job_question_id.present? && global_question_id.present?
      errors.add(:base, "cannot have both job_question and global_question")
    end
  end

  def required_question_has_value
    return unless question&.required?
    return if value.present?

    errors.add(:value, "is required for '#{question.label}'")
  end
end
