# frozen_string_literal: true

# Legacy wrapper - delegates to CvExtractor for backwards compatibility
class EducationExtractor
  class ExtractionError < CvExtractor::ExtractionError; end

  def self.extract(cv_text)
    result = CvExtractor.extract(cv_text)
    result[:education]
  end
end
