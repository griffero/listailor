# frozen_string_literal: true

class CoverLetterEvaluator
  DEFAULT_PROMPT = <<~PROMPT.freeze
    Evaluate this cover letter as if you were a contrarian founder who only hires people with independent thinking.

    Do NOT comment on writing quality or tone.

    Answer the following:

    1. Does this person demonstrate original thinking, or are they repeating standard narratives?
    2. Is there evidence they've seen a truth others missed, or acted against consensus?
    3. What is the strongest non-obvious signal of talent here?
    4. What is the biggest red flag that suggests conformity or shallow thinking?
    5. If this person were wrong, how would they most likely be wrong?

    Assume you have 200 candidates with stronger credentials.
    Be intellectually ruthless.

    End with a binary decision: ADVANCE or REJECT.
  PROMPT

  def initialize(cover_letter_text)
    @cover_letter_text = cover_letter_text
  end

  def evaluate
    return nil if @cover_letter_text.blank?

    prompt = Setting.get("cover_letter_evaluation_prompt").presence || DEFAULT_PROMPT

    client = OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"],
      request_timeout: 60
    )

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: "COVER LETTER:\n\n#{@cover_letter_text}" }
        ],
        temperature: 0.3
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return nil if content.blank?

    decision = extract_decision(content)

    {
      evaluation: content,
      decision: decision,
      evaluated_at: Time.current.iso8601
    }
  rescue StandardError => e
    Rails.logger.error("CoverLetterEvaluator error: #{e.message}")
    nil
  end

  private

  def extract_decision(content)
    # Look for ADVANCE or REJECT at the end of the response
    last_lines = content.split("\n").last(5).join(" ").upcase
    
    if last_lines.include?("ADVANCE")
      "advance"
    elsif last_lines.include?("REJECT")
      "reject"
    else
      "unclear"
    end
  end
end
