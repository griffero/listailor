class TeamtailorBackfillAnswersJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  
  LOCK_KEY = "teamtailor_backfill_answers"
  LOCK_TTL = 15.minutes
  BATCH_SIZE = 50
  
  def perform
    return unless acquire_lock
    
    client = Teamtailor::Client.new
    
    # Find applications without custom answers
    apps_without_answers = Application
      .joins(:job_posting)
      .joins("INNER JOIN job_questions ON job_questions.job_posting_id = applications.job_posting_id")
      .where("job_questions.teamtailor_id IS NOT NULL")
      .where.not(id: ApplicationAnswer.select(:application_id).where.not(job_question_id: nil))
      .distinct
      .limit(BATCH_SIZE)
    
    Rails.logger.info("TeamtailorBackfillAnswersJob: Processing #{apps_without_answers.count} applications")
    
    apps_without_answers.find_each do |app|
      begin
        resp = client.get("/job-applications/#{app.teamtailor_id}", params: {"include" => "job,candidate,stage"})
        payload = resp["data"]
        included_index = Teamtailor::Utils.index_included(resp["included"])
        
        Teamtailor::Mappers::ApplicationMapper.apply_answers!(app, payload, included_index, client: client)
        app.mark_teamtailor_full_sync_if_ready!(synced_at: Time.current)
        heartbeat_lock if (app.id % 25).zero?
      rescue => e
        Rails.logger.warn("Failed to backfill answers for app #{app.id}: #{e.message}")
      end
    end
    
    Rails.logger.info("TeamtailorBackfillAnswersJob: Completed")
  ensure
    release_lock
  end
  
  private
  
  def acquire_lock
    owner = "backfill-answers-#{Process.pid}-#{Thread.current.object_id}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    Rails.logger.info("TeamtailorBackfillAnswersJob skipped: lock held")
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
