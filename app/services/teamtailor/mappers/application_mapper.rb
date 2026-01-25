module Teamtailor
  module Mappers
    class ApplicationMapper
      def self.upsert!(payload, included_index: {}, client: Client.new, skip_answers: false)
        return nil if payload.blank?

        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]

        job_posting = resolve_job(payload, included_index, client: client)
        candidate = resolve_candidate(payload, included_index, client: client)
        stage = resolve_stage(payload, included_index, job_posting: job_posting)

        return nil if job_posting.blank? || candidate.blank?

        application = Application.find_or_initialize_by(teamtailor_id: teamtailor_id)
        application.job_posting = job_posting
        application.candidate = candidate
        application.current_stage = stage if stage.present?
        application.source = Utils.attr(attributes, "source")
        application.utm_source = Utils.attr(attributes, "utm_source", "utm-source")
        application.utm_medium = Utils.attr(attributes, "utm_medium", "utm-medium")
        application.utm_campaign = Utils.attr(attributes, "utm_campaign", "utm-campaign")
        application.utm_term = Utils.attr(attributes, "utm_term", "utm-term")
        application.utm_content = Utils.attr(attributes, "utm_content", "utm-content")

        application.created_at = Utils.parse_time(Utils.attr(attributes, "created_at", "created-at")) if application.new_record?

        application.save!

        unless skip_answers
          apply_cover_letter!(application, attributes)
          apply_answers!(application, payload, included_index, client: client)
        end
        sync_stage_transition!(application, stage, attributes)
        state_synced_at = Utils.parse_time(Utils.attr(attributes, "updated_at", "updated-at")) || Time.current
        application.mark_teamtailor_state_synced!(synced_at: state_synced_at)
        application.mark_teamtailor_full_sync_if_ready!(synced_at: state_synced_at) unless skip_answers

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

      def self.apply_answers!(application, payload, included_index, client:)
        return if payload.blank?

        answers = extract_answers(payload, included_index)
        answers_index = included_index

        if answers.blank?
          response = fetch_answers_from_api(payload, client: client)
          answers = response[:answers]
          answers_index = response[:included_index] || included_index
        end

        if answers.blank?
          apply_answers_from_cache(application, client: client)
          return
        end

        answers.each_with_index do |answer_payload, index|
          question = resolve_question(
            answer_payload,
            application.job_posting,
            answers_index,
            index,
            client: client
          )
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
        value = Utils.attr(attributes, "value", "answer", "response", "text")
        value = attributes["boolean"] if value.nil?
        value = attributes["number"] if value.nil?
        value = attributes["date"] if value.nil?
        value = attributes["choices"] if value.nil?
        return value.join(", ") if value.is_a?(Array)

        value || answer_payload["value"]
      end

      def self.resolve_question(answer_payload, job_posting, included_index, index, client:)
        relationships = answer_payload.fetch("relationships", {})
        question_ref = relationships.dig("question", "data")

        question_payload =
          if question_ref
            Utils.find_included(included_index, question_ref["type"], question_ref["id"])
          else
            answer_payload["question"]
          end

        if question_payload.blank?
          question_payload = fetch_question_for_answer(answer_payload, client: client)
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

      def self.fetch_question_for_answer(answer_payload, client:)
        answer_id = answer_payload["id"]
        return nil if answer_id.blank?

        client.get("/answers/#{answer_id}/question")["data"]
      rescue RuntimeError => e
        return nil if e.message.include?("404")
        raise
      end

      def self.question_from_payload(question_payload, job_posting, position)
        QuestionMapper.upsert_job_question!(question_payload, job_posting: job_posting, position: position)
      end

      def self.resolve_job(payload, _included_index, client:)
        job_ref = payload.dig("relationships", "job", "data")
        teamtailor_id = job_ref&.fetch("id", nil)

        return nil if teamtailor_id.blank?

        job = JobPosting.find_by(teamtailor_id: teamtailor_id)
        return job if job.present?

        begin
          response = client.get("/jobs/#{teamtailor_id}", params: { "include" => "questions,stages" })
          data = response["data"]
          return nil if data.blank?

          Teamtailor::Mappers::JobPostingMapper.upsert!(
            data,
            included_index: Teamtailor::Utils.index_included(response["included"])
          )
        rescue RuntimeError => e
          return nil if e.message.include?("404")
          raise
        end

        JobPosting.find_by(teamtailor_id: teamtailor_id)
      end

      def self.resolve_candidate(payload, _included_index, client:)
        candidate_ref = payload.dig("relationships", "candidate", "data")
        teamtailor_id = candidate_ref&.fetch("id", nil)

        return nil if teamtailor_id.blank?

        candidate = Candidate.find_by(teamtailor_id: teamtailor_id)
        return candidate if candidate.present?

        begin
          response = client.get("/candidates/#{teamtailor_id}")
          data = response["data"]
          return nil if data.blank?

          Teamtailor::Mappers::CandidateMapper.upsert!(data)
        rescue RuntimeError => e
          return nil if e.message.include?("404")
          raise
        end

        Candidate.find_by(teamtailor_id: teamtailor_id)
      end

      def self.resolve_stage(payload, included_index, job_posting: nil)
        stage_ref = payload.dig("relationships", "stage", "data")
        teamtailor_id = stage_ref&.fetch("id", nil)
        return nil if teamtailor_id.blank?

        # Try to find stage for this specific job first, then fall back to global
        stage =
          if job_posting
            PipelineStage.find_by(teamtailor_id: teamtailor_id, job_posting_id: job_posting.id) ||
              PipelineStage.find_by(teamtailor_id: teamtailor_id, job_posting_id: nil)
          else
            PipelineStage.find_by(teamtailor_id: teamtailor_id)
          end

        return stage if stage.present?

        stage_payload = Utils.find_included(included_index, "stages", teamtailor_id)
        return nil if stage_payload.blank?

        StageMapper.upsert!(stage_payload, job_posting: job_posting)
      end

      def self.sync_stage_transition!(application, stage, attributes)
        return if stage.blank?

        changed_at = Utils.parse_time(Utils.attr(attributes, "changed_stage_at", "changed-stage-at")) ||
          application.created_at || Time.current

        application.sync_stage!(stage, occurred_at: changed_at)
      end

      def self.fetch_answers_from_api(payload, client:)
        application_id = payload["id"]
        return { answers: [], included_index: {} } if application_id.blank?

        begin
          response = client.get(
            "/job-applications/#{application_id}",
            params: { "include" => "answers,answers.question" }
          )
          included_index = Utils.index_included(response["included"])
          answers = extract_answers(response["data"], included_index)
          return { answers: answers, included_index: included_index } if answers.any?
        rescue RuntimeError => e
          unless e.message.include?("404")
            raise
          end
        end

        endpoints = [
          "/job-applications/#{application_id}/answers",
          "/job-applications/#{application_id}/answers?include=question",
          "/answers?filter[job-application]=#{application_id}&include=question",
          "/answers?filter[job-application-id]=#{application_id}&include=question"
        ]

        endpoints.each do |endpoint|
          begin
            responses = []
            client.paginate(endpoint, params: { "page[size]" => 25 }) do |response|
              responses << response
            end
            answers = responses.flat_map { |resp| resp["data"] || [] }
            included_index = Utils.index_included(responses.flat_map { |resp| resp["included"] || [] })
            return { answers: answers, included_index: included_index } if answers.any?
          rescue RuntimeError => e
            next if e.message.include?("404")
            raise
          end
        end

        { answers: [], included_index: {} }
      end

      def self.apply_answers_from_cache(application, client:)
        candidate_id = application.candidate&.teamtailor_id
        return if candidate_id.blank?

        job_questions = application.job_posting.job_questions.where.not(teamtailor_id: nil)
        cache = Thread.current[:teamtailor_answers_cache]
        cache ||= Teamtailor::AnswersCache.new(client: client)
        Thread.current[:teamtailor_answers_cache] = cache

        if job_questions.empty?
          response = cache.answers_for_candidate(candidate_id)
          response[:answers].each_with_index do |answer_payload, index|
            question = resolve_question(
              answer_payload,
              application.job_posting,
              response[:included_index],
              index,
              client: client
            )
            next if question.blank?

            answer = ApplicationAnswer.find_or_initialize_by(application: application, job_question: question)
            answer.value = extract_answer_value(answer_payload)
            answer.save!
          end
          return
        end

        job_questions.each do |question|
          answer_payload = cache.answer_for(question.teamtailor_id, candidate_id)
          next if answer_payload.blank?

          answer = ApplicationAnswer.find_or_initialize_by(application: application, job_question: question)
          answer.value = extract_answer_value(answer_payload)
          answer.save!
        end
      end
    end
  end
end
