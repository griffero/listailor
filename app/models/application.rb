class Application < ApplicationRecord
  belongs_to :job_posting
  belongs_to :candidate
  belongs_to :current_stage, class_name: "PipelineStage", optional: true

  has_many :application_answers, dependent: :destroy
  has_many :stage_transitions, class_name: "ApplicationStageTransition", dependent: :destroy
  has_many :events, class_name: "ApplicationEvent", dependent: :destroy
  has_many :email_messages, dependent: :destroy
  has_many :interview_events, dependent: :destroy

  has_one_attached :cv

  validates :job_posting_id, uniqueness: { scope: :candidate_id, message: "already has an application from this candidate" }
  validate :cv_content_type, if: -> { cv.attached? }

  accepts_nested_attributes_for :application_answers

  scope :for_job, ->(job_posting_id) { where(job_posting_id: job_posting_id) }
  scope :for_stage, ->(stage_id) { where(current_stage_id: stage_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :missing_teamtailor_full_sync, -> { where(teamtailor_full_sync_at: nil) }
  scope :search, ->(query) {
    return all if query.blank?
    joins(:candidate).where(
      "candidates.first_name ILIKE :q OR candidates.last_name ILIKE :q OR candidates.email ILIKE :q",
      q: "%#{query}%"
    )
  }

  after_create :set_initial_stage
  after_create :record_created_event
  after_create :enqueue_webhook

  def move_to_stage!(new_stage, user: nil)
    return if current_stage_id == new_stage.id

    old_stage = current_stage

    transaction do
      stage_transitions.create!(
        from_stage: old_stage,
        to_stage: new_stage,
        transitioned_at: Time.current
      )

      update!(current_stage: new_stage)

      events.create!(
        event_type: "stage_change",
        message: "Moved from #{old_stage&.name || 'No Stage'} to #{new_stage.name}",
        payload: {
          from_stage_id: old_stage&.id,
          from_stage_name: old_stage&.name,
          to_stage_id: new_stage.id,
          to_stage_name: new_stage.name
        },
        occurred_at: Time.current,
        created_by_user: user
      )
    end
  end

  def sync_stage!(new_stage, occurred_at: Time.current)
    return if new_stage.blank?

    old_stage = current_stage
    if old_stage&.id == new_stage.id
      return if stage_transitions.where(to_stage: new_stage).exists?

      stage_transitions.create!(
        from_stage: nil,
        to_stage: new_stage,
        transitioned_at: occurred_at
      )
      return
    end

    transaction do
      update!(current_stage: new_stage) if current_stage_id != new_stage.id

      stage_transitions.create!(
        from_stage: old_stage,
        to_stage: new_stage,
        transitioned_at: occurred_at
      )
    end
  end

  def timeline_items
    items = []

    # Application created
    items << {
      type: "application_created",
      occurred_at: created_at,
      message: "Application submitted"
    }

    # Stage transitions (skip the initial one)
    stage_transitions.includes(:from_stage, :to_stage).each do |transition|
      next if transition.from_stage.nil? # Skip initial transition

      items << {
        type: "stage_change",
        occurred_at: transition.transitioned_at,
        message: "Stage changed from #{transition.from_stage.name} to #{transition.to_stage.name}"
      }
    end

    # Email messages
    email_messages.each do |email|
      items << {
        type: email.direction == "outbound" ? "email_sent" : "email_received",
        occurred_at: email.sent_at || email.received_at || email.created_at,
        message: email.subject,
        data: email
      }
    end

    # Interview events
    interview_events.each do |interview|
      items << {
        type: "interview",
        occurred_at: interview.scheduled_at,
        message: interview.title,
        data: interview
      }
    end

    # Application events (notes, external events)
    events.where.not(event_type: %w[application_created stage_change]).each do |event|
      items << {
        type: event.event_type,
        occurred_at: event.occurred_at,
        message: event.message,
        data: event
      }
    end

    items.sort_by { |item| item[:occurred_at] }.reverse
  end

  def custom_questions_ready?
    questions = job_posting.job_questions.where.not(teamtailor_id: nil)
    return true if questions.empty?

    answered_ids = application_answers
      .where(job_question_id: questions.select(:id))
      .distinct
      .pluck(:job_question_id)

    answered_ids.size >= questions.count
  end

  def mark_teamtailor_state_synced!(synced_at: Time.current)
    update_column(:teamtailor_state_synced_at, synced_at)
  end

  def mark_teamtailor_full_sync_if_ready!(synced_at: Time.current)
    return false unless custom_questions_ready?

    update_column(:teamtailor_full_sync_at, synced_at)
    true
  end

  private

  def set_initial_stage
    return if current_stage_id.present?

    initial_stage = PipelineStage.ordered.first
    return unless initial_stage

    update_column(:current_stage_id, initial_stage.id)

    stage_transitions.create!(
      from_stage: nil,
      to_stage: initial_stage,
      transitioned_at: Time.current
    )
  end

  def record_created_event
    events.create!(
      event_type: "application_created",
      message: "Application submitted for #{job_posting.title}",
      payload: {
        source: source,
        utm_source: utm_source,
        utm_medium: utm_medium,
        utm_campaign: utm_campaign
      },
      occurred_at: Time.current
    )
  end

  def enqueue_webhook
    OutboundWebhookJob.perform_later(id)
  end

  def cv_content_type
    acceptable_types = ["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
    unless cv.content_type.in?(acceptable_types)
      errors.add(:cv, "must be a PDF, DOC, or DOCX file")
    end
  end
end
