class SendEmailJob < ApplicationJob
  queue_as :default

  # Exponential backoff for retries
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  discard_on ActiveRecord::RecordNotFound

  def perform(email_message_id)
    email = EmailMessage.find(email_message_id)
    return if email.sent? # Already sent

    webhook_url = Setting.n8n_send_email_webhook_url
    
    if webhook_url.blank?
      Rails.logger.warn "No n8n send email webhook URL configured, marking email as failed"
      email.mark_failed!
      return
    end

    payload = {
      email_message_id: email.id,
      application_id: email.application_id,
      from: email.from_address,
      to: email.to_address,
      subject: email.subject,
      body_html: email.body_html,
      candidate: {
        name: email.application.candidate.full_name,
        email: email.application.candidate.email
      },
      job: {
        title: email.application.job_posting.title
      }
    }

    response = HTTParty.post(
      webhook_url,
      body: payload.to_json,
      headers: {
        "Content-Type" => "application/json",
        "User-Agent" => "Listailor-ATS/1.0"
      },
      timeout: 30
    )

    if response.success?
      provider_message_id = response.parsed_response["message_id"] rescue nil
      email.mark_sent!(provider_message_id: provider_message_id)
      Rails.logger.info "Email #{email.id} sent successfully"
    else
      raise "Email send failed: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    # Mark as failed after all retries exhausted
    if executions >= 5
      email&.mark_failed!
    end
    raise e
  end
end
