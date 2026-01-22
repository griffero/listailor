module Teamtailor
  module Mappers
    class ApplicationMapper
      def self.upsert!(payload, included_index: {})
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]

        job_posting = resolve_job(payload, included_index)
        candidate = resolve_candidate(payload, included_index)

        return nil if job_posting.blank? || candidate.blank?

        application = Application.find_or_initialize_by(teamtailor_id: teamtailor_id)
        application.job_posting = job_posting
        application.candidate = candidate
        application.source = Utils.attr(attributes, "source")
        application.utm_source = Utils.attr(attributes, "utm_source", "utm-source")
        application.utm_medium = Utils.attr(attributes, "utm_medium", "utm-medium")
        application.utm_campaign = Utils.attr(attributes, "utm_campaign", "utm-campaign")
        application.utm_term = Utils.attr(attributes, "utm_term", "utm-term")
        application.utm_content = Utils.attr(attributes, "utm_content", "utm-content")

        application.created_at = Utils.parse_time(Utils.attr(attributes, "created_at", "created-at")) if application.new_record?

        application.save!

        apply_cover_letter!(application, attributes)
        apply_answers!(application, payload, included_index)

        application
      end

      def self.apply_cover_letter!(application, attributes)
        cover_letter = Utils.attr(attributes, "cover_letter", "cover-letter", "coverLetter")
        return if cover_letter.blank?

        question = QuestionMapper.cover_letter_question
        answer = ApplicationAnswer.find_or_initialize_by(application: application, global_question: question)
        answer.value = cover_letter
        answer.save!
      end

      def self.apply_answers!(application, payload, included_index)
        answers = extract_answers(payload, included_index)
        return if answers.blank?

        answers.each_with_index do |answer_payload, index|
          question = resolve_question(answer_payload, application.job_posting, included_index, index)
          next if question.blank?

          answer = ApplicationAnswer.find_or_initialize_by(application: application, job_question: question)
          answer.value = extract_answer_value(answer_payload)
          answer.save!
        end
      end

      def self.extract_answers(payload, included_index)
        attributes = payload.fetch("attributes", {})
        return attributes["answers"] if attributes["answers"].is_a?(Array)

        relationships = payload.fetch("relationships", {})
        answers_data = relationships.dig("answers", "data")
        return [] unless answers_data.is_a?(Array)

        answers_data.filter_map do |answer_ref|
          Utils.find_included(included_index, answer_ref["type"], answer_ref["id"]) || answer_ref
        end
      end

      def self.extract_answer_value(answer_payload)
        attributes = answer_payload.fetch("attributes", {})
        Utils.attr(attributes, "value", "answer", "response") || answer_payload["value"]
      end

      def self.resolve_question(answer_payload, job_posting, included_index, index)
        relationships = answer_payload.fetch("relationships", {})
        question_ref = relationships.dig("question", "data")

        question_payload = if question_ref
          Utils.find_included(included_index, question_ref["type"], question_ref["id"])
        else
          answer_payload["question"]
        end

        return question_from_payload(question_payload, job_posting, index) if question_payload.present?

        label = answer_payload.dig("attributes", "question") || answer_payload["question"]
        return nil if label.blank?

        JobQuestion.find_or_initialize_by(job_posting: job_posting, label: label).tap do |question|
          question.kind ||= "short_text"
          question.position ||= index
          question.required = false if question.required.nil?
          question.save!
        end
      end

      def self.question_from_payload(question_payload, job_posting, position)
        QuestionMapper.upsert_job_question!(question_payload, job_posting: job_posting, position: position)
      end

      def self.resolve_job(payload, included_index)
        job_ref = payload.dig("relationships", "job", "data")
        teamtailor_id = job_ref&.fetch("id", nil)

        if teamtailor_id.present?
          JobPosting.find_by(teamtailor_id: teamtailor_id)
        else
          nil
        end
      end

      def self.resolve_candidate(payload, included_index)
        candidate_ref = payload.dig("relationships", "candidate", "data")
        teamtailor_id = candidate_ref&.fetch("id", nil)

        if teamtailor_id.present?
          Candidate.find_by(teamtailor_id: teamtailor_id)
        else
          nil
        end
      end
    end
  end
end
