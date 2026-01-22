class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # Known setting keys
  KEYS = %w[
    outbound_webhook_url
    n8n_send_email_webhook_url
    embed_allowed_origins
    departments
    locations
  ].freeze

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value)
    setting
  end

  def self.outbound_webhook_url
    get("outbound_webhook_url") || ENV["OUTBOUND_WEBHOOK_URL"]
  end

  def self.n8n_send_email_webhook_url
    get("n8n_send_email_webhook_url") || ENV["N8N_SEND_EMAIL_WEBHOOK_URL"]
  end

  def self.embed_allowed_origins
    origins = get("embed_allowed_origins") || ENV["EMBED_ALLOWED_ORIGINS"] || ""
    origins.split(",").map(&:strip).reject(&:blank?)
  end

  def self.departments
    json_value = get("departments")
    return [] if json_value.blank?
    JSON.parse(json_value)
  rescue JSON::ParserError
    []
  end

  def self.departments=(list)
    set("departments", list.to_json)
  end

  def self.locations
    json_value = get("locations")
    return [] if json_value.blank?
    JSON.parse(json_value)
  rescue JSON::ParserError
    []
  end

  def self.locations=(list)
    set("locations", list.to_json)
  end
end
