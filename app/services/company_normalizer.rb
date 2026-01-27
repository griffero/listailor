# frozen_string_literal: true

class CompanyNormalizer
  # Known company aliases - normalized name => [aliases]
  COMPANY_ALIASES = {
    "Nestlé" => %w[nestle nestlé nestle\ chile nestle\ holding nestlé\ chile],
    "Microsoft" => %w[microsoft msft microsoft\ corporation microsoft\ chile],
    "Google" => %w[google alphabet google\ chile google\ inc],
    "Amazon" => %w[amazon aws amazon\ web\ services amazon\ chile],
    "Meta" => %w[meta facebook meta\ platforms fb],
    "Apple" => %w[apple apple\ inc apple\ chile],
    "IBM" => %w[ibm international\ business\ machines ibm\ chile],
    "Accenture" => %w[accenture accenture\ chile],
    "Deloitte" => %w[deloitte deloitte\ chile deloitte\ &\ touche],
    "PwC" => %w[pwc pricewaterhousecoopers price\ waterhouse\ coopers pwc\ chile],
    "KPMG" => %w[kpmg kpmg\ chile],
    "EY" => %w[ey ernst\ &\ young ernst\ young ey\ chile],
    "McKinsey" => %w[mckinsey mckinsey\ &\ company],
    "BCG" => %w[bcg boston\ consulting\ group boston\ consulting],
    "Bain" => %w[bain bain\ &\ company bain\ company],
    "Banco de Chile" => %w[banco\ de\ chile bch],
    "Banco Santander" => %w[banco\ santander santander santander\ chile],
    "BCI" => %w[bci banco\ de\ crédito\ e\ inversiones banco\ credito\ inversiones],
    "Itaú" => %w[itau itaú itaú\ chile itau\ chile itaú\ corpbanca],
    "Falabella" => %w[falabella saga\ falabella falabella\ retail],
    "Cencosud" => %w[cencosud jumbo paris],
    "Walmart Chile" => %w[walmart\ chile walmart lider],
    "LATAM Airlines" => %w[latam latam\ airlines lan lan\ chile],
    "Copec" => %w[copec empresas\ copec],
    "ENAP" => %w[enap empresa\ nacional\ del\ petróleo],
    "Codelco" => %w[codelco corporación\ nacional\ del\ cobre],
    "SQM" => %w[sqm sociedad\ química\ y\ minera],
    "Enel Chile" => %w[enel\ chile enel chilectra endesa\ chile],
    "Telefónica" => %w[telefonica telefónica movistar movistar\ chile],
    "Claro" => %w[claro claro\ chile],
    "Entel" => %w[entel empresa\ nacional\ de\ telecomunicaciones],
    "Fintoc" => %w[fintoc],
    "Cornershop" => %w[cornershop cornershop\ by\ uber],
    "NotCo" => %w[notco the\ not\ company not\ company],
    "Betterfly" => %w[betterfly],
    "Buk" => %w[buk],
    "Houm" => %w[houm],
    "Xepelin" => %w[xepelin]
  }.freeze

  # Build reverse lookup hash for quick matching
  ALIAS_TO_NORMALIZED = COMPANY_ALIASES.each_with_object({}) do |(normalized, aliases), hash|
    aliases.each { |a| hash[a.downcase.strip] = normalized }
    hash[normalized.downcase.strip] = normalized
  end.freeze

  class << self
    def normalize(company_name)
      return nil if company_name.blank?

      cleaned = clean_name(company_name)
      
      # Direct match in aliases
      return ALIAS_TO_NORMALIZED[cleaned] if ALIAS_TO_NORMALIZED.key?(cleaned)

      # Fuzzy match - check if any alias is contained in the company name
      ALIAS_TO_NORMALIZED.each do |alias_name, normalized|
        return normalized if cleaned.include?(alias_name) || alias_name.include?(cleaned)
      end

      # No match found - return cleaned/titleized version
      titleize_company(company_name)
    end

    def normalize_all(work_experiences)
      return [] if work_experiences.blank?

      work_experiences.map do |exp|
        next exp unless exp.is_a?(Hash) && exp["company"].present?

        exp.merge(
          "company_normalized" => normalize(exp["company"]),
          "company_original" => exp["company"]
        )
      end
    end

    private

    def clean_name(name)
      name.to_s
          .downcase
          .strip
          .gsub(/\s+/, " ")           # Normalize whitespace
          .gsub(/[,.]$/, "")          # Remove trailing punctuation
          .gsub(/\b(s\.?a\.?|ltda\.?|spa|inc\.?|corp\.?|llc|chile)\b/i, "") # Remove legal suffixes
          .strip
    end

    def titleize_company(name)
      # Smart titleize that handles special cases
      name.to_s.strip.split(/\s+/).map do |word|
        if word.match?(/^[A-Z]{2,}$/)
          word # Keep all-caps acronyms
        else
          word.capitalize
        end
      end.join(" ")
    end
  end
end
