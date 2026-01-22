class User < ApplicationRecord
  has_secure_token :magic_login_token

  has_many :created_email_templates, class_name: "EmailTemplate", foreign_key: :created_by_user_id, dependent: :nullify
  has_many :created_application_events, class_name: "ApplicationEvent", foreign_key: :created_by_user_id, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save :downcase_email

  def send_magic_link!
    regenerate_magic_login_token
    update!(magic_login_sent_at: Time.current)
    AuthMailer.magic_link(self).deliver_now
  end

  def magic_link_valid?
    magic_login_token.present? &&
      magic_login_sent_at.present? &&
      magic_login_sent_at > 15.minutes.ago
  end

  def consume_magic_link!
    update!(
      magic_login_token: nil,
      magic_login_sent_at: nil,
      last_signed_in_at: Time.current
    )
  end

  private

  def downcase_email
    self.email = email.downcase.strip
  end
end
