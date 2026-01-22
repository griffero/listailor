class EmailMessage < ApplicationRecord
  DIRECTIONS = %w[inbound outbound].freeze
  STATUSES = %w[queued sent failed received].freeze

  belongs_to :application

  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :from_address, presence: true
  validates :to_address, presence: true
  validates :subject, presence: true

  scope :ordered, -> { order(Arel.sql("COALESCE(sent_at, received_at, created_at) DESC")) }
  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound, -> { where(direction: "inbound") }
  scope :sent, -> { where(status: "sent") }
  scope :queued, -> { where(status: "queued") }
  scope :failed, -> { where(status: "failed") }

  def outbound?
    direction == "outbound"
  end

  def inbound?
    direction == "inbound"
  end

  def sent?
    status == "sent"
  end

  def queued?
    status == "queued"
  end

  def failed?
    status == "failed"
  end

  def mark_sent!(provider_message_id: nil)
    update!(
      status: "sent",
      sent_at: Time.current,
      provider_message_id: provider_message_id
    )
  end

  def mark_failed!
    update!(status: "failed")
  end
end
