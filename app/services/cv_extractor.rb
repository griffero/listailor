# frozen_string_literal: true

class CvExtractor
  class ExtractionError < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Eres un experto en analizar CVs/currículums. Tu tarea es extraer información educacional y experiencia laboral.

    Reglas para EDUCACIÓN:
    1. UNIVERSIDAD: Extrae SOLO la carrera principal universitaria (pregrado). NO incluyas:
       - Diplomados, cursos, certificaciones
       - Postgrados (maestrías, doctorados) - estos van aparte si los piden
    2. COLEGIO: Extrae el colegio de educación secundaria/media si aparece
    3. El año de graduación es opcional, solo si está claramente indicado

    Reglas para EXPERIENCIA LABORAL:
    1. Extrae TODAS las empresas donde ha trabajado
    2. Incluye el cargo/posición si está disponible
    3. Incluye fechas de inicio y fin (mes/año) si están disponibles
    4. Ordena de más reciente a más antiguo
    5. Si es el trabajo actual, pon end_date como null

    Responde SOLO con JSON válido, sin texto adicional.
  PROMPT

  USER_PROMPT_TEMPLATE = <<~PROMPT.freeze
    Analiza el siguiente CV y extrae la información:

    ---
    %{cv_text}
    ---

    Responde con este formato JSON exacto:
    {
      "education": {
        "university": {
          "name": "Nombre de la universidad",
          "degree": "Nombre de la carrera de pregrado",
          "graduation_year": "2020"
        },
        "school": {
          "name": "Nombre del colegio"
        }
      },
      "work_experience": [
        {
          "company": "Nombre de la empresa",
          "position": "Cargo o título",
          "start_date": "2020-01",
          "end_date": "2023-06",
          "is_current": false
        }
      ]
    }

    - Si no hay universidad, pon "university": null
    - Si no hay colegio, pon "school": null
    - Si no hay experiencia laboral, pon "work_experience": []
    - Las fechas deben estar en formato YYYY-MM si están disponibles, o solo YYYY si solo hay año
    - Si es el trabajo actual, pon "is_current": true y "end_date": null
  PROMPT

  def self.extract(cv_text)
    new.extract(cv_text)
  end

  def initialize(client: nil)
    @client = client || OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_API_KEY"),
      request_timeout: 60
    )
  end

  def extract(cv_text)
    return { education: nil, work_experience: [] } if cv_text.blank?

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
    return { education: nil, work_experience: [] } if content.blank?

    parsed = JSON.parse(content)
    normalize_response(parsed)
  rescue JSON::ParserError => e
    Rails.logger.error("CvExtractor: Invalid JSON response - #{e.message}")
    Rails.logger.error("CvExtractor: Raw response - #{content}")
    raise ExtractionError, "OpenAI returned invalid JSON"
  rescue Faraday::Error, OpenAI::Error => e
    Rails.logger.error("CvExtractor: API error - #{e.class}: #{e.message}")
    raise ExtractionError, "OpenAI API error: #{e.message}"
  end

  private

  def normalize_response(parsed)
    result = {
      education: normalize_education(parsed["education"]),
      work_experience: normalize_work_experience(parsed["work_experience"])
    }
    result
  end

  def normalize_education(education_data)
    return nil unless education_data.is_a?(Hash)

    result = {}

    if education_data["university"].is_a?(Hash) && education_data["university"]["name"].present?
      result["university"] = {
        "name" => education_data["university"]["name"]&.strip,
        "degree" => education_data["university"]["degree"]&.strip,
        "graduation_year" => education_data["university"]["graduation_year"]&.to_s&.strip.presence
      }.compact
    end

    if education_data["school"].is_a?(Hash) && education_data["school"]["name"].present?
      result["school"] = {
        "name" => education_data["school"]["name"]&.strip
      }.compact
    end

    result.presence
  end

  def normalize_work_experience(work_data)
    return [] unless work_data.is_a?(Array)

    experiences = work_data.filter_map do |exp|
      next unless exp.is_a?(Hash) && exp["company"].present?

      {
        "company" => exp["company"]&.strip,
        "position" => exp["position"]&.strip.presence,
        "start_date" => normalize_date(exp["start_date"]),
        "end_date" => normalize_date(exp["end_date"]),
        "is_current" => exp["is_current"] == true
      }.compact
    end

    # Normalize company names
    CompanyNormalizer.normalize_all(experiences)
  end

  def normalize_date(date_str)
    return nil if date_str.blank?

    date_str = date_str.to_s.strip

    # Handle various date formats
    case date_str
    when /^\d{4}(-\d{2})?$/ # YYYY or YYYY-MM
      date_str
    when /^(\d{2})\/(\d{4})$/ # MM/YYYY
      "#{$2}-#{$1}"
    when /^(\w+)\s+(\d{4})$/i # Month YYYY
      month_num = Date::MONTHNAMES.index($1.capitalize) || Date::ABBR_MONTHNAMES.index($1.capitalize)
      month_num ? "#{$2}-#{month_num.to_s.rjust(2, '0')}" : $2
    else
      # Try to extract year at least
      date_str[/\d{4}/]
    end
  end
end
