class JobQuestion < ApplicationRecord
  KINDS = %w[long_text short_text number checkbox select].freeze

  belongs_to :job_posting
  has_many :application_answers, dependent: :destroy

  validates :label, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(position: :asc) }

  before_validation :set_default_position, on: :create

  def select_options
    return [] unless kind == "select"
    options || []
  end

  private

  def set_default_position
    return if position.present?
    max_position = job_posting&.job_questions&.maximum(:position) || -1
    self.position = max_position + 1
  end
end
