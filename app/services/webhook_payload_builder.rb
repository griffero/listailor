class WebhookPayloadBuilder
  def self.build_application_created(application)
    application = application.reload

    {
      event: "application.created",
      timestamp: Time.current.iso8601,
      data: {
        application_id: application.id,
        application_url: application_url(application),
        job: {
          id: application.job_posting.id,
          title: application.job_posting.title,
          slug: application.job_posting.slug,
          department: application.job_posting.department,
          location: application.job_posting.location
        },
        candidate: {
          id: application.candidate.id,
          first_name: application.candidate.first_name,
          last_name: application.candidate.last_name,
          email: application.candidate.email,
          phone: application.candidate.phone,
          linkedin_url: application.candidate.linkedin_url
        },
        source: application.source,
        utm: {
          source: application.utm_source,
          medium: application.utm_medium,
          campaign: application.utm_campaign,
          term: application.utm_term,
          content: application.utm_content
        },
        answers: application.application_answers.ordered.map do |answer|
          {
            question_id: answer.job_question_id,
            question: answer.question_label,
            answer: answer.value
          }
        end,
        cv_url: cv_url(application),
        stage: {
          id: application.current_stage&.id,
          name: application.current_stage&.name
        },
        created_at: application.created_at.iso8601
      }
    }
  end

  private

  def self.application_url(application)
    host = ENV.fetch("APP_HOST", "http://localhost:3000")
    "#{host}/app/applications/#{application.id}"
  end

  def self.cv_url(application)
    return nil unless application.cv.attached?

    host = ENV.fetch("APP_HOST", "http://localhost:3000")
    Rails.application.routes.url_helpers.rails_blob_url(application.cv, host: host)
  rescue StandardError
    nil
  end
end
