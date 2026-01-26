class EducationExtractor
  class ExtractionError < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Eres un experto en analizar CVs/currículums. Tu tarea es extraer información educacional.

    Reglas importantes:
    1. UNIVERSIDAD: Extrae SOLO la carrera principal universitaria (pregrado). NO incluyas:
       - Diplomados
       - Cursos
       - Certificaciones
       - Postgrados (maestrías, doctorados) - estos van aparte si los piden
    2. COLEGIO: Extrae el colegio de educación secundaria/media si aparece
    3. Si no encuentras información, devuelve null para ese campo
    4. El año de graduación es opcional, solo si está claramente indicado

    Responde SOLO con JSON válido, sin texto adicional.
  PROMPT

  USER_PROMPT_TEMPLATE = <<~PROMPT.freeze
    Analiza el siguiente CV y extrae la información educacional:

    ---
    %{cv_text}
    ---

    Responde con este formato JSON exacto:
    {
      "university": {
        "name": "Nombre de la universidad",
        "degree": "Nombre de la carrera de pregrado",
        "graduation_year": "2020"
      },
      "school": {
        "name": "Nombre del colegio"
      }
    }

    Si no hay universidad, pon "university": null
    Si no hay colegio, pon "school": null
  PROMPT

  def self.extract(cv_text)
    new.extract(cv_text)
  end

  def initialize(client: nil)
    @client = client || OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_API_KEY"),
      request_timeout: 30
    )
  end

  def extract(cv_text)
    return nil if cv_text.blank?

    # Truncate very long CVs to avoid token limits
    truncated_text = cv_text.truncate(15_000, omission: "\n\n[...texto truncado...]")

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: format(USER_PROMPT_TEMPLATE, cv_text: truncated_text) }
        ],
        temperature: 0.1,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return nil if content.blank?

    parsed = JSON.parse(content)
    normalize_response(parsed)
  rescue JSON::ParserError => e
    Rails.logger.error("EducationExtractor: Invalid JSON response - #{e.message}")
    Rails.logger.error("EducationExtractor: Raw response - #{content}")
    raise ExtractionError, "OpenAI returned invalid JSON"
  rescue Faraday::Error, OpenAI::Error => e
    Rails.logger.error("EducationExtractor: API error - #{e.class}: #{e.message}")
    raise ExtractionError, "OpenAI API error: #{e.message}"
  end

  private

  def normalize_response(parsed)
    result = {}

    if parsed["university"].is_a?(Hash) && parsed["university"]["name"].present?
      result["university"] = {
        "name" => parsed["university"]["name"]&.strip,
        "degree" => parsed["university"]["degree"]&.strip,
        "graduation_year" => parsed["university"]["graduation_year"]&.to_s&.strip.presence
      }.compact
    end

    if parsed["school"].is_a?(Hash) && parsed["school"]["name"].present?
      result["school"] = {
        "name" => parsed["school"]["name"]&.strip
      }.compact
    end

    result.presence
  end
end
