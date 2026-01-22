class InterviewEvent < ApplicationRecord
  belongs_to :application

  validates :scheduled_at, presence: true
  validates :title, presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :upcoming, -> { where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }
  scope :ordered, -> { order(scheduled_at: :asc) }

  def participants_list
    participants || []
  end

  def end_time
    scheduled_at + duration_minutes.minutes
  end

  def upcoming?
    scheduled_at > Time.current
  end

  def past?
    !upcoming?
  end
end
