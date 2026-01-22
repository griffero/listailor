class TemplateRenderer
  # Safe template renderer that only replaces known placeholders
  # Variables use syntax: {{variable.path}}

  VARIABLE_PATTERN = /\{\{([a-z_.]+)\}\}/i

  def self.render(template, context)
    return "" if template.blank?

    template.gsub(VARIABLE_PATTERN) do |match|
      variable_path = $1.downcase
      resolve_variable(variable_path, context) || match
    end
  end

  def self.resolve_variable(path, context)
    parts = path.split(".")
    return nil if parts.length < 2

    object_name = parts[0]
    attribute = parts[1]

    object = context[object_name.to_sym] || context[object_name]
    return nil unless object

    value = case object
    when Hash
      object[attribute.to_sym] || object[attribute]
    else
      object.respond_to?(attribute) ? object.send(attribute) : nil
    end

    value.to_s.presence
  end

  # Build context from an application
  def self.context_for_application(application)
    {
      candidate: {
        first_name: application.candidate.first_name,
        last_name: application.candidate.last_name,
        email: application.candidate.email
      },
      job: {
        title: application.job_posting.title,
        department: application.job_posting.department,
        location: application.job_posting.location
      },
      application: {
        url: Rails.application.routes.url_helpers.app_application_url(application, host: ENV.fetch("APP_HOST", "localhost:3000"))
      },
      stage: {
        name: application.current_stage&.name
      }
    }
  end
end
