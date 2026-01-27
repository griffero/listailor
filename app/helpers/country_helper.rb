# frozen_string_literal: true

module CountryHelper
  COUNTRY_FLAGS = {
    "cl" => "🇨🇱",
    "mx" => "🇲🇽",
    "co" => "🇨🇴",
    "pe" => "🇵🇪",
    "ar" => "🇦🇷",
    "br" => "🇧🇷",
    "us" => "🇺🇸"
  }.freeze

  def self.infer_country_from_title(title)
    return "cl" if title.blank?

    title_lower = title.downcase
    return "mx" if title_lower.include?("méxico") || title_lower.include?("mexico")
    return "co" if title_lower.include?("colombia")
    return "pe" if title_lower.include?("perú") || title_lower.include?("peru")
    return "ar" if title_lower.include?("argentina")
    return "br" if title_lower.include?("brasil") || title_lower.include?("brazil")
    return "us" if title_lower.include?("usa") || title_lower.include?("united states")

    "cl" # Default to Chile
  end

  def self.flag_for_country(country_code)
    COUNTRY_FLAGS[country_code] || "🌎"
  end

  def self.flag_from_title(title)
    country = infer_country_from_title(title)
    flag_for_country(country)
  end
end
