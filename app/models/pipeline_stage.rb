class PipelineStage < ApplicationRecord
  KINDS = %w[active hired rejected].freeze

  has_many :applications, foreign_key: :current_stage_id, dependent: :nullify
  has_many :transitions_from, class_name: "ApplicationStageTransition", foreign_key: :from_stage_id, dependent: :nullify
  has_many :transitions_to, class_name: "ApplicationStageTransition", foreign_key: :to_stage_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :kind, presence: true, inclusion: { in: KINDS }

  scope :ordered, -> { order(position: :asc) }
  scope :active, -> { where(kind: "active") }
  scope :terminal, -> { where(kind: %w[hired rejected]) }

  def active?
    kind == "active"
  end

  def hired?
    kind == "hired"
  end

  def rejected?
    kind == "rejected"
  end

  def terminal?
    hired? || rejected?
  end
end
