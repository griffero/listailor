class PipelineStage < ApplicationRecord
  KINDS = %w[active hired rejected].freeze
  CANONICAL_STAGES = %w[inbox reviewing interview technical cultural references offer hired rejected].freeze

  belongs_to :job_posting, optional: true
  has_many :applications, foreign_key: :current_stage_id, dependent: :nullify
  has_many :transitions_from, class_name: "ApplicationStageTransition", foreign_key: :from_stage_id, dependent: :nullify
  has_many :transitions_to, class_name: "ApplicationStageTransition", foreign_key: :to_stage_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :teamtailor_id, uniqueness: { scope: :job_posting_id }, allow_nil: true
  validates :canonical_stage, inclusion: { in: CANONICAL_STAGES }, allow_nil: true

  before_save :set_canonical_stage, if: -> { canonical_stage.blank? }

  scope :ordered, -> { order(position: :asc) }
  scope :active, -> { where(kind: "active") }
  scope :terminal, -> { where(kind: %w[hired rejected]) }
  scope :for_job, ->(job_id) { where(job_posting_id: job_id) }
  scope :global, -> { where(job_posting_id: nil) }

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

  # Infer canonical stage from name and kind
  def infer_canonical_stage
    return "hired" if kind == "hired"
    return "rejected" if kind == "rejected"

    name_lower = name.downcase

    # Order matters - more specific patterns first
    return "inbox" if name_lower.match?(/inbox|postulaci[oó]n|respondido|aplicaci[oó]n|bandeja/)
    return "reviewing" if name_lower.match?(/review|revisan|revisi[oó]n/)
    return "technical" if name_lower.match?(/t[eé]cnic|desaf[ií]o|challenge|coding/)
    return "cultural" if name_lower.match?(/cultural|fit|valores/)
    return "references" if name_lower.match?(/referencia|reference/)
    return "offer" if name_lower.match?(/offer|oferta|offered/)
    return "interview" if name_lower.match?(/interview|entrevista/)
    return "hired" if name_lower.match?(/hired|contratad/)
    return "rejected" if name_lower.match?(/reject|rechaz/)

    # Default fallback
    "reviewing"
  end

  private

  def set_canonical_stage
    self.canonical_stage = infer_canonical_stage
  end
end
