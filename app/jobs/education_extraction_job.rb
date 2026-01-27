class EducationExtractionJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "education_extraction"
  LOCK_TTL = 30.minutes
  BATCH_SIZE = 100

  def perform
    return unless acquire_lock

    # Find applications with CV but without processing_completed_at
    pending_apps = Application
      .joins(:cv_attachment)
      .where(processing_completed_at: nil)
      .order(created_at: :desc)
      .limit(BATCH_SIZE)

    Rails.logger.info("EducationExtractionJob: Processing #{pending_apps.count} applications")

    pending_apps.find_each do |app|
      process_application(app)
      heartbeat_lock if (app.id % 10).zero?
    end

    # Also mark apps without CV as completed (nothing to extract)
    mark_apps_without_cv_as_completed

    Rails.logger.info("EducationExtractionJob: Completed")
  ensure
    release_lock
  end

  private

  def process_application(app)
    Rails.logger.info("EducationExtractionJob: Processing application #{app.id}")

    begin
      # Only process PDFs for now
      unless app.cv.content_type == "application/pdf"
        Rails.logger.info("EducationExtractionJob: Skipping non-PDF CV for app #{app.id}")
        app.update!(processing_completed_at: Time.current)
        return
      end

      # Download and extract text from PDF
      cv_text = app.cv.open do |file|
        PdfTextExtractor.extract(file.path)
      end

      if cv_text.blank?
        Rails.logger.warn("EducationExtractionJob: No text extracted from CV for app #{app.id}")
        app.update!(processing_completed_at: Time.current)
        return
      end

      # Extract education using AI
      education = EducationExtractor.extract(cv_text)

      # Save results
      app.update!(
        education: education,
        processing_completed_at: Time.current
      )

      Rails.logger.info("EducationExtractionJob: Successfully extracted education for app #{app.id}")
    rescue PdfTextExtractor::ExtractionError => e
      Rails.logger.error("EducationExtractionJob: PDF extraction failed for app #{app.id}: #{e.message}")
      # Mark as completed to not block indefinitely
      app.update!(processing_completed_at: Time.current)
    rescue EducationExtractor::ExtractionError => e
      Rails.logger.error("EducationExtractionJob: AI extraction failed for app #{app.id}: #{e.message}")
      # Don't mark as completed - will retry on next run
    rescue StandardError => e
      Rails.logger.error("EducationExtractionJob: Unexpected error for app #{app.id}: #{e.class}: #{e.message}")
    end
  end

  def mark_apps_without_cv_as_completed
    # Applications that have had their answers synced but have no CV
    apps_without_cv = Application
      .left_joins(:cv_attachment)
      .where(active_storage_attachments: { id: nil })
      .where(processing_completed_at: nil)
      .where.not(teamtailor_full_sync_at: nil)
      .limit(BATCH_SIZE)

    count = apps_without_cv.update_all(processing_completed_at: Time.current)
    Rails.logger.info("EducationExtractionJob: Marked #{count} apps without CV as completed") if count > 0
  end

  def acquire_lock
    owner = "education-extraction-#{Process.pid}-#{Thread.current.object_id}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    Rails.logger.info("EducationExtractionJob skipped: lock held")
    false
  end

  def release_lock
    return if @lock_owner.blank?

    Teamtailor::SyncLock.release(@lock_key, owner: @lock_owner)
  ensure
    @lock_owner = nil
  end

  def heartbeat_lock
    return if @lock_owner.blank?

    Teamtailor::SyncLock.heartbeat(@lock_key, owner: @lock_owner)
  end
end
