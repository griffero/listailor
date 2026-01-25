module Teamtailor
  class AnswersCache
    def initialize(client:)
      @client = client
      @cache = {} # candidate_id => { question_id => answer }
      @included = {} # candidate_id => [included question payloads]
    end

    def answer_for(question_id, candidate_id)
      return nil if question_id.blank? || candidate_id.blank?

      load_candidate(candidate_id) unless @cache.key?(candidate_id)
      @cache.dig(candidate_id, question_id)
    end

    def answers_for_candidate(candidate_id)
      return { answers: [], included_index: {} } if candidate_id.blank?

      load_candidate(candidate_id) unless @cache.key?(candidate_id)
      included = @included[candidate_id] || []
      {
        answers: @cache[candidate_id].values,
        included_index: Utils.index_included(included)
      }
    end

    private

    def load_candidate(candidate_id)
      answers_by_question = {}
      included = []

      @client.paginate("/candidates/#{candidate_id}/answers", params: {
        "include" => "question",
        "page[size]" => 25
      }) do |response|
        included.concat(response["included"] || [])
        (response["data"] || []).each do |answer|
          question_id = answer.dig("relationships", "question", "data", "id")
          next if question_id.blank?

          answers_by_question[question_id] = answer
        end
      end

      @cache[candidate_id] = answers_by_question
      @included[candidate_id] = included
    rescue RuntimeError => e
      if e.message.include?("404")
        @cache[candidate_id] = {}
        @included[candidate_id] = []
        return
      end

      raise
    end
  end
end
