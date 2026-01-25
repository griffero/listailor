module Teamtailor
  module Mappers
    class JobPostingMapper
      PLACEHOLDER_DESCRIPTION = "Imported from Teamtailor.".freeze

      def self.upsert!(payload, included_index: {})
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

        upsert_questions!(job, payload, included_index)
        upsert_stages!(job, payload, included_index)
        job
      end
      
      def self.upsert_stages!(job, payload, included_index)
        stage_refs = payload.dig("relationships", "stages", "data")
        return unless stage_refs.is_a?(Array)

        stage_refs.each do |stage_ref|
          stage_payload = Utils.find_included(included_index, stage_ref["type"], stage_ref["id"])
          next if stage_payload.blank?

          StageMapper.upsert!(stage_payload, job_posting: job)
        end
      end

      def self.upsert_questions!(job, payload, included_index)
        question_refs = payload.dig("relationships", "questions", "data")
        return unless question_refs.is_a?(Array)

        question_refs.each_with_index do |question_ref, index|
          question_payload = Utils.find_included(included_index, question_ref["type"], question_ref["id"])
          next if question_payload.blank?

          QuestionMapper.upsert_job_question!(question_payload, job_posting: job, position: index)
        end
      end
    end
  end
end
