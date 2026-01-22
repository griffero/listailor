class ApplicationEvent < ApplicationRecord
  EVENT_TYPES = %w[
    application_created
    stage_change
    note
    email_sent
    email_received
    interview_scheduled
    external_event
  ].freeze

  belongs_to :application
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true

  scope :ordered, -> { order(occurred_at: :desc) }
  scope :notes, -> { where(event_type: "note") }
  scope :external_events, -> { where(event_type: "external_event") }

  def user_created?
    created_by_user.present?
  end

  def system_event?
    event_type.in?(%w[application_created stage_change])
  end
end
