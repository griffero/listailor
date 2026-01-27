class CvBackfillJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "cv_backfill"
  LOCK_TTL = 30.minutes
  BATCH_SIZE = 500
  THREAD_POOL_SIZE = 10

  def perform
    return unless acquire_lock

    # Find applications without CV that have a teamtailor_id
    apps_without_cv = Application
      .left_joins(:cv_attachment)
      .where(active_storage_attachments: { id: nil })
      .where.not(teamtailor_id: nil)
      .joins(:candidate)
      .where.not(candidates: { teamtailor_id: nil })
      .order(created_at: :desc)
      .limit(BATCH_SIZE)
      .to_a

    Rails.logger.info("CvBackfillJob: Processing #{apps_without_cv.count} applications with #{THREAD_POOL_SIZE} threads")

    # Process in parallel using thread pool
    queue = Queue.new
    apps_without_cv.each { |app| queue << app }
    THREAD_POOL_SIZE.times { queue << :done }

    mutex = Mutex.new
    processed = 0
    failed = 0

    threads = THREAD_POOL_SIZE.times.map do
      Thread.new do
        client = Teamtailor::Client.new
        while (app = queue.pop) != :done
          begin
            process_application(app, client)
            mutex.synchronize { processed += 1 }
          rescue StandardError => e
            mutex.synchronize { failed += 1 }
            Rails.logger.warn("CvBackfillJob: Thread error for app #{app.id}: #{e.message}")
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

    Rails.logger.info("CvBackfillJob: Completed - processed: #{processed}, failed: #{failed}")
  ensure
    release_lock
  end

  private

  def process_application(app, client)
    candidate_tt_id = app.candidate.teamtailor_id
    return if candidate_tt_id.blank?

    Rails.logger.info("CvBackfillJob: Fetching resume for application #{app.id}, candidate #{candidate_tt_id}")

    begin
      response = client.get("/candidates/#{candidate_tt_id}")
      data = response["data"]
      return if data.blank?

      attributes = data.fetch("attributes", {})
      resume = attributes["resume"]
      
      # Resume can be a direct URL string or an object with url/file-name
      resume_url = resume.is_a?(String) ? resume : resume&.dig("url")
      resume_filename = resume.is_a?(Hash) ? (resume["file-name"] || resume["filename"]) : nil

      if resume_url.present?
        CvDownloader.download_and_attach(app, url: resume_url, filename: resume_filename)
      else
        Rails.logger.info("CvBackfillJob: No resume URL for application #{app.id}")
      end
    rescue StandardError => e
      Rails.logger.warn("CvBackfillJob: Error processing application #{app.id}: #{e.message}")
    end
  end

  def acquire_lock
    owner = "cv-backfill-#{Process.pid}-#{Thread.current.object_id}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    Rails.logger.info("CvBackfillJob skipped: lock held")
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
