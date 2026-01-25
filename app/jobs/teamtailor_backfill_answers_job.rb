class TeamtailorBackfillAnswersJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  
  LOCK_KEY = 972_654_322
  BATCH_SIZE = 500
  
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
    @lock_acquired = ActiveModel::Type::Boolean.new.cast(
      ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_KEY})")
    )
    
    return true if @lock_acquired
    
    Rails.logger.info("TeamtailorBackfillAnswersJob skipped: lock held")
    false
  end
  
  def release_lock
    return unless @lock_acquired
    
    ActiveRecord::Base.connection.select_value("SELECT pg_advisory_unlock(#{LOCK_KEY})")
  ensure
    @lock_acquired = false
  end
end
