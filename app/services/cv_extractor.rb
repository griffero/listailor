# frozen_string_literal: true

class CvExtractor
  class ExtractionError < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Eres un experto en analizar CVs/currículums. Tu tarea es extraer información educacional, experiencia laboral e insights del candidato.

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

    Reglas para INSIGHTS:
    1. has_startup_experience: true si ha trabajado en startups, scale-ups, o empresas pequeñas de tecnología (ej: Rappi, Cornershop, Notion, empresas con "seed", "Series A/B/C", YC, etc). También si menciona "startup" o trabajó en empresa fundada recientemente.
    2. has_year_tenure: true si ALGUNO de sus trabajos duró 1 año o más (basado en las fechas)
    3. has_personal_projects: true si menciona proyectos personales, side projects, freelance significativo, fue fundador/co-fundador de algo, tiene portfolio, o contribuciones open source.

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
      ],
      "insights": {
        "has_startup_experience": true,
        "has_year_tenure": true,
        "has_personal_projects": false
      }
    }

    - Si no hay universidad, pon "university": null
    - Si no hay colegio, pon "school": null
    - Si no hay experiencia laboral, pon "work_experience": []
    - Las fechas deben estar en formato YYYY-MM si están disponibles, o solo YYYY si solo hay año
    - Si es el trabajo actual, pon "is_current": true y "end_date": null
    - Para insights, usa true/false según las reglas del sistema
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
    return { education: nil, work_experience: [], insights: {} } if cv_text.blank?

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
    return { education: nil, work_experience: [], insights: {} } if content.blank?

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
    work_exp = normalize_work_experience(parsed["work_experience"])
    insights = normalize_insights(parsed["insights"], work_exp)

    {
      education: normalize_education(parsed["education"]),
      work_experience: work_exp,
      insights: insights
    }
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

  def normalize_insights(insights_data, work_experiences)
    result = {
      has_startup_experience: false,
      has_year_tenure: false,
      has_personal_projects: false
    }

    if insights_data.is_a?(Hash)
      result[:has_startup_experience] = insights_data["has_startup_experience"] == true
      result[:has_year_tenure] = insights_data["has_year_tenure"] == true
      result[:has_personal_projects] = insights_data["has_personal_projects"] == true
    end

    # Double-check year tenure from work experiences if AI missed it
    result[:has_year_tenure] ||= check_year_tenure(work_experiences)

    result
  end

  def check_year_tenure(work_experiences)
    return false unless work_experiences.is_a?(Array)

    work_experiences.any? do |exp|
      next false unless exp["start_date"].present?

      start_date = parse_work_date(exp["start_date"])
      next false unless start_date

      end_date = if exp["is_current"]
                   Date.current
                 elsif exp["end_date"].present?
                   parse_work_date(exp["end_date"])
                 end
      next false unless end_date

      # Check if duration is >= 12 months
      months = ((end_date.year - start_date.year) * 12) + (end_date.month - start_date.month)
      months >= 12
    end
  end

  def parse_work_date(date_str)
    return nil if date_str.blank?

    case date_str
    when /^(\d{4})-(\d{2})$/ # YYYY-MM
      Date.new($1.to_i, $2.to_i, 1)
    when /^(\d{4})$/ # YYYY only
      Date.new($1.to_i, 6, 1) # Assume mid-year
    end
  rescue ArgumentError
    nil
  end
end
