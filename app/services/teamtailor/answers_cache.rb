module Teamtailor
  class AnswersCache
    def initialize(client:)
      @client = client
      @cache = {}
    end

    def answer_for(question_id, candidate_id)
      return nil if question_id.blank? || candidate_id.blank?

      load_question(question_id) unless @cache.key?(question_id)
      @cache[question_id][candidate_id]
    end

    private

    def load_question(question_id)
      answers_by_candidate = {}

      @client.paginate("/answers", params: {
        "filter[question]" => question_id,
        "include" => "candidate",
        "page[size]" => 50
      }) do |response|
        (response["data"] || []).each do |answer|
          candidate_id = answer.dig("relationships", "candidate", "data", "id")
          next if candidate_id.blank?

          answers_by_candidate[candidate_id] = answer
        end
      end

      @cache[question_id] = answers_by_candidate
    rescue RuntimeError => e
      if e.message.include?("404")
        @cache[question_id] = {}
        return
      end

      raise
    end
  end
end
