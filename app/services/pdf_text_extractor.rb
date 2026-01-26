class PdfTextExtractor
  class ExtractionError < StandardError; end

  def self.extract(io_or_path)
    new.extract(io_or_path)
  end

  def extract(io_or_path)
    reader = PDF::Reader.new(io_or_path)
    text = reader.pages.map(&:text).join("\n\n")
    text.strip.presence
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    Rails.logger.error("PdfTextExtractor: Failed to parse PDF - #{e.message}")
    raise ExtractionError, "Could not parse PDF: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("PdfTextExtractor: Unexpected error - #{e.class}: #{e.message}")
    raise ExtractionError, "Unexpected error extracting PDF text: #{e.message}"
  end
end
