class OutboundWebhookJob < ApplicationJob
  queue_as :default

  # Exponential backoff: 3s, 18s, 83s, 258s, 627s, ~17min, ~42min, ~1h42m, ~4h, ~10h
  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  discard_on ActiveRecord::RecordNotFound

  def perform(application_id)
    webhook_url = Setting.outbound_webhook_url
    return if webhook_url.blank?

    application = Application.find(application_id)
    payload = WebhookPayloadBuilder.build_application_created(application)

    response = HTTParty.post(
      webhook_url,
      body: payload.to_json,
      headers: {
        "Content-Type" => "application/json",
        "User-Agent" => "Listailor-ATS/1.0"
      },
      timeout: 30
    )

    unless response.success?
      raise "Webhook delivery failed: #{response.code} - #{response.body}"
    end

    Rails.logger.info "Webhook delivered for application #{application_id}: #{response.code}"
  end
end
