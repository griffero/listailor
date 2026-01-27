class EducationExtractionJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "education_extraction"
  LOCK_TTL = 30.minutes
  BATCH_SIZE = 200
  THREAD_POOL_SIZE = 5

  def perform
    return unless acquire_lock

    # Find applications with CV but without processing_completed_at
    pending_apps = Application
      .joins(:cv_attachment)
      .where(processing_completed_at: nil)
      .order(created_at: :desc)
      .limit(BATCH_SIZE)
      .to_a

    Rails.logger.info("EducationExtractionJob: Processing #{pending_apps.count} applications with #{THREAD_POOL_SIZE} threads")

    # Process in parallel using thread pool
    queue = Queue.new
    pending_apps.each { |app| queue << app }
    THREAD_POOL_SIZE.times { queue << :done }

    mutex = Mutex.new
    processed = 0
    failed = 0

    threads = THREAD_POOL_SIZE.times.map do
      Thread.new do
        while (app = queue.pop) != :done
          begin
            process_application(app)
            mutex.synchronize { processed += 1 }
          rescue StandardError => e
            mutex.synchronize { failed += 1 }
            Rails.logger.warn("EducationExtractionJob: Thread error for app #{app.id}: #{e.message}")
          end
        end
      end
    end

    # Wait for all threads with periodic heartbeat
    until threads.all? { |t| !t.alive? }
      sleep 5
      heartbeat_lock
    end

    threads.each(&:join)

    # Also mark apps without CV as completed (nothing to extract)
    mark_apps_without_cv_as_completed

    Rails.logger.info("EducationExtractionJob: Completed - processed: #{processed}, failed: #{failed}")
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

      # Extract education, work experience, and insights using AI
      extracted = CvExtractor.extract(cv_text)
      insights = extracted[:insights] || {}

      # Evaluate cover letter if present and not already evaluated
      cover_letter_result = evaluate_cover_letter(app)

      # Save results
      update_attrs = {
        education: extracted[:education],
        work_experience: extracted[:work_experience],
        has_startup_experience: insights[:has_startup_experience],
        has_year_tenure: insights[:has_year_tenure],
        has_personal_projects: insights[:has_personal_projects],
        processing_completed_at: Time.current
      }

      if cover_letter_result
        update_attrs[:cover_letter_evaluation] = cover_letter_result
        update_attrs[:cover_letter_decision] = cover_letter_result[:decision]
      end

      app.update!(update_attrs)

      Rails.logger.info("EducationExtractionJob: Successfully extracted data for app #{app.id} (#{extracted[:work_experience]&.size || 0} jobs, startup=#{insights[:has_startup_experience]}, tenure=#{insights[:has_year_tenure]}, projects=#{insights[:has_personal_projects]}, cover_letter=#{cover_letter_result&.dig(:decision) || 'none'})")
    rescue PdfTextExtractor::ExtractionError => e
      Rails.logger.error("EducationExtractionJob: PDF extraction failed for app #{app.id}: #{e.message}")
      # Mark as completed to not block indefinitely
      app.update!(processing_completed_at: Time.current)
    rescue CvExtractor::ExtractionError => e
      Rails.logger.error("EducationExtractionJob: AI extraction failed for app #{app.id}: #{e.message}")
      # Don't mark as completed - will retry on next run
    rescue StandardError => e
      Rails.logger.error("EducationExtractionJob: Unexpected error for app #{app.id}: #{e.class}: #{e.message}")
    end
  end

  def evaluate_cover_letter(app)
    # Skip if already evaluated
    return nil if app.cover_letter_decision.present?

    # Get all application answers
    answers = app.application_answers.includes(:global_question).ordered
    return nil if answers.empty?

    # Format all answers for evaluation
    answers_text = answers.map do |answer|
      next if answer.value.blank?
      "**#{answer.question_label}**\n#{answer.value}"
    end.compact.join("\n\n")

    return nil if answers_text.blank?

    # Evaluate using AI with all answers
    CoverLetterEvaluator.new(answers_text).evaluate
  rescue StandardError => e
    Rails.logger.warn("EducationExtractionJob: Cover letter evaluation failed for app #{app.id}: #{e.message}")
    nil
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
