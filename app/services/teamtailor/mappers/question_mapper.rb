module Teamtailor
  module Mappers
    class QuestionMapper
      def self.upsert_job_question!(payload, job_posting:, position: nil)
        return nil unless payload.is_a?(Hash)

        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]

        if job_posting.present?
          question = JobQuestion.find_or_initialize_by(job_posting: job_posting, teamtailor_id: teamtailor_id)
        else
          question = JobQuestion.find_or_initialize_by(teamtailor_id: teamtailor_id)
        end
        question.label = Utils.attr(attributes, "label", "question", "title") || question.label
        question.kind = map_kind(Utils.attr(attributes, "type", "kind", "question_type"))
        question.required = Utils.attr(attributes, "required") unless Utils.attr(attributes, "required").nil?
        question.options = normalize_options(Utils.attr(attributes, "options", "choices"))
        question.position = position if position.present?

        question.label ||= "Imported question #{teamtailor_id}"
        question.kind ||= "short_text"
        question.required = false if question.required.nil?

        question.save!
        question
      end

      def self.cover_letter_question
        GlobalQuestion.find_or_create_by!(label: "Cover Letter (Teamtailor)") do |question|
          question.kind = "long_text"
          question.required = false
          question.position = (GlobalQuestion.maximum(:position) || -1) + 1
        end
      end

      def self.map_kind(value)
        return nil if value.blank?

        normalized = value.to_s.downcase
        return "select" if normalized.include?("select") || normalized.include?("choice") || normalized.include?("multiple")
        return "checkbox" if normalized.include?("checkbox") || normalized.include?("boolean")
        return "number" if normalized.include?("number")
        return "long_text" if normalized.include?("long")

        "short_text"
      end

      def self.normalize_options(value)
        return nil if value.blank?
        return value if value.is_a?(Array)

        Array(value)
      end
    end
  end
end
