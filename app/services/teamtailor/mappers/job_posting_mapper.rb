module Teamtailor
  module Mappers
    class JobPostingMapper
      PLACEHOLDER_DESCRIPTION = "Imported from Teamtailor.".freeze

      def self.upsert!(payload)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        job = JobPosting.find_or_initialize_by(teamtailor_id: teamtailor_id)

        job.title = Utils.attr(attributes, "title", "name") || job.title
        job.description = Utils.attr(attributes, "description", "body", "text", "pitch") || job.description
        job.department = Utils.attr(attributes, "department", "department_name")
        job.location = Utils.attr(attributes, "location", "city", "country")
        job.published_at = Utils.parse_time(Utils.attr(attributes, "published_at", "published-at"))
        job.archived_at = Utils.parse_time(Utils.attr(attributes, "archived_at", "archived-at"))

        job.title = "Imported job #{teamtailor_id}" if job.title.blank?
        job.description = PLACEHOLDER_DESCRIPTION if job.description.blank?

        job.save!
        job
      end
    end
  end
end
