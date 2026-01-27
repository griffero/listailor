# frozen_string_literal: true

class CoverLetterEvaluator
  DEFAULT_PROMPT = <<~PROMPT.freeze
    Evaluate this job application as if you were a contrarian founder who only hires people with independent thinking.
    You will receive all the answers the candidate provided in their application form.

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

  def initialize(application_answers_text)
    @application_answers_text = application_answers_text
  end

  def evaluate
    return nil if @application_answers_text.blank?

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
          { role: "user", content: "APPLICATION ANSWERS:\n\n#{@application_answers_text}" }
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
    # Look for explicit decision patterns first
    content_upper = content.upcase
    
    # Check for "Decision: REJECT" or "Decision: ADVANCE" pattern (most reliable)
    if content_upper =~ /DECISION[:\s]+REJECT/
      return "reject"
    elsif content_upper =~ /DECISION[:\s]+ADVANCE/
      return "advance"
    end
    
    # Check for standalone ADVANCE or REJECT at the very end (last line)
    last_line = content.strip.split("\n").last.to_s.upcase.strip
    
    # Check if last line is just the decision word
    return "advance" if last_line == "ADVANCE" || last_line == "ADVANCE."
    return "reject" if last_line == "REJECT" || last_line == "REJECT."
    
    # Check if last line contains the decision as a final statement
    if last_line =~ /\bREJECT\b/ && !last_line.include?("ADVANCE")
      return "reject"
    elsif last_line =~ /\bADVANCE\b/ && !last_line.include?("REJECT")
      return "advance"
    end
    
    # Fallback: look at last few lines, but be more careful
    last_section = content.split("\n").last(3).join(" ").upcase
    
    # Only match if it's clearly a decision, not just mentioning the words
    if last_section =~ /\bREJECT\b(?!.*\bADVANCE\b)/
      "reject"
    elsif last_section =~ /\bADVANCE\b(?!.*\bREJECT\b)/
      "advance"
    else
      "unclear"
    end
  end
end
