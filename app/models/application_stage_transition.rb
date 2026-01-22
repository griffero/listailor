class ApplicationStageTransition < ApplicationRecord
  belongs_to :application
  belongs_to :from_stage, class_name: "PipelineStage", optional: true
  belongs_to :to_stage, class_name: "PipelineStage"

  validates :transitioned_at, presence: true

  scope :ordered, -> { order(transitioned_at: :asc) }
  scope :for_stage, ->(stage_id) { where(to_stage_id: stage_id) }
  scope :in_period, ->(start_date, end_date) { where(transitioned_at: start_date..end_date) }

  def duration_in_stage
    return nil if from_stage.nil?

    next_transition = application.stage_transitions
      .where("transitioned_at > ?", transitioned_at)
      .order(transitioned_at: :asc)
      .first

    end_time = next_transition&.transitioned_at || Time.current
    end_time - transitioned_at
  end
end
