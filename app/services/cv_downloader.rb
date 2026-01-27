require "open-uri"

class CvDownloader
  class DownloadError < StandardError; end

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  MAX_FILE_SIZE = 10.megabytes

  def self.download_and_attach(application, url:, filename: nil)
    new.download_and_attach(application, url: url, filename: filename)
  end

  def download_and_attach(application, url:, filename: nil)
    return false if url.blank?
    return false if application.cv.attached?

    Rails.logger.info("CvDownloader: Downloading CV for application #{application.id} from #{url}")

    begin
      # Download the file
      uri = URI.parse(url)
      downloaded_file = uri.open(
        "User-Agent" => "Listailor-ATS/1.0",
        read_timeout: 30,
        open_timeout: 10
      )

      # Check file size
      if downloaded_file.size > MAX_FILE_SIZE
        Rails.logger.warn("CvDownloader: File too large (#{downloaded_file.size} bytes) for application #{application.id}")
        return false
      end

      # Determine content type and filename
      content_type = downloaded_file.content_type || guess_content_type(url)
      
      unless ALLOWED_CONTENT_TYPES.include?(content_type)
        Rails.logger.warn("CvDownloader: Invalid content type #{content_type} for application #{application.id}")
        return false
      end

      final_filename = filename.presence || extract_filename(url, content_type)

      # Attach to application
      application.cv.attach(
        io: downloaded_file,
        filename: final_filename,
        content_type: content_type
      )

      Rails.logger.info("CvDownloader: Successfully attached CV to application #{application.id}")
      true
    rescue OpenURI::HTTPError => e
      Rails.logger.warn("CvDownloader: HTTP error downloading CV for application #{application.id}: #{e.message}")
      false
    rescue URI::InvalidURIError => e
      Rails.logger.warn("CvDownloader: Invalid URL for application #{application.id}: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("CvDownloader: Error downloading CV for application #{application.id}: #{e.class} - #{e.message}")
      false
    end
  end

  private

  EXTENSION_TO_CONTENT_TYPE = {
    ".pdf" => "application/pdf",
    ".doc" => "application/msword",
    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  }.freeze

  CONTENT_TYPE_TO_EXTENSION = {
    "application/pdf" => ".pdf",
    "application/msword" => ".doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx"
  }.freeze

  def guess_content_type(url)
    ext = File.extname(URI.parse(url).path).downcase
    EXTENSION_TO_CONTENT_TYPE[ext] || "application/pdf"
  end

  def extract_filename(url, content_type)
    # Try to get filename from URL
    uri = URI.parse(url)
    path_filename = File.basename(uri.path) if uri.path.present?

    return path_filename if path_filename.present? && path_filename.include?(".")

    # Generate filename based on content type
    extension = CONTENT_TYPE_TO_EXTENSION[content_type] || ".pdf"
    "resume#{extension}"
  end
end
