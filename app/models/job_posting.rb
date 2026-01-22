class JobPosting < ApplicationRecord
  has_many :job_questions, dependent: :destroy
  has_many :applications, dependent: :restrict_with_error

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
  validates :description, presence: true

  before_validation :generate_slug, on: :create

  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def unpublish!
    update!(published_at: nil)
  end

  def toggle_publish!
    published? ? unpublish! : publish!
  end

  private

  def generate_slug
    return if slug.present?
    return if title.blank?

    base_slug = title.parameterize
    self.slug = base_slug

    counter = 1
    while JobPosting.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
