class Candidate < ApplicationRecord
  has_many :applications, dependent: :restrict_with_error

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_uniqueness_case_insensitive

  before_save :downcase_email

  scope :search, ->(query) {
    return all if query.blank?
    where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{query}%")
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.find_or_create_by_email(email:, first_name:, last_name:, phone: nil, linkedin_url: nil)
    candidate = find_by("lower(email) = ?", email.downcase.strip)

    if candidate
      # Update with new info if provided
      candidate.update(
        first_name: first_name.presence || candidate.first_name,
        last_name: last_name.presence || candidate.last_name,
        phone: phone.presence || candidate.phone,
        linkedin_url: linkedin_url.presence || candidate.linkedin_url
      )
      candidate
    else
      create!(
        email: email,
        first_name: first_name,
        last_name: last_name,
        phone: phone,
        linkedin_url: linkedin_url
      )
    end
  end

  private

  def downcase_email
    self.email = email.downcase.strip
  end

  def email_uniqueness_case_insensitive
    return if email.blank?

    existing = Candidate.where("lower(email) = ?", email.downcase.strip)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:email, "has already been taken")
    end
  end
end
