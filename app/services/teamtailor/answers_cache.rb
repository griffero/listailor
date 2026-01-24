module Teamtailor
  class AnswersCache
    def initialize(client:)
      @client = client
      @cache = {} # candidate_id => { question_id => answer }
    end

    def answer_for(question_id, candidate_id)
      return nil if question_id.blank? || candidate_id.blank?

      load_candidate(candidate_id) unless @cache.key?(candidate_id)
      @cache.dig(candidate_id, question_id)
    end

    private

    def load_candidate(candidate_id)
      answers_by_question = {}

      @client.paginate("/candidates/#{candidate_id}/answers", params: {
        "include" => "question",
        "page[size]" => 25
      }) do |response|
        (response["data"] || []).each do |answer|
          question_id = answer.dig("relationships", "question", "data", "id")
          next if question_id.blank?

          answers_by_question[question_id] = answer
        end
      end

      @cache[candidate_id] = answers_by_question
    rescue RuntimeError => e
      if e.message.include?("404")
        @cache[candidate_id] = {}
        return
      end

      raise
    end
  end
end
