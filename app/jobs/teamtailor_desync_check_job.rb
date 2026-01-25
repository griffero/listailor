class TeamtailorDesyncCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  LOCK_KEY = 972_654_323
  BATCH_SIZE = 200

  def perform
    return unless acquire_lock

    client = Teamtailor::Client.new

    apps_needing_answers = Application
      .missing_teamtailor_full_sync
      .where.not(teamtailor_id: nil)
      .where(<<~SQL)
        EXISTS (
          SELECT 1 FROM job_questions jq
          WHERE jq.job_posting_id = applications.job_posting_id
            AND jq.teamtailor_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM application_answers aa
              WHERE aa.application_id = applications.id
                AND aa.job_question_id = jq.id
            )
        )
      SQL
      .limit(BATCH_SIZE)

    Rails.logger.info("TeamtailorDesyncCheckJob: Processing #{apps_needing_answers.count} applications")

    apps_needing_answers.find_each do |app|
      begin
        resp = client.get("/job-applications/#{app.teamtailor_id}", params: {"include" => "job,candidate,stage"})
        payload = resp["data"]
        included_index = Teamtailor::Utils.index_included(resp["included"])

        Teamtailor::Mappers::ApplicationMapper.apply_answers!(app, payload, included_index, client: client)
        app.mark_teamtailor_state_synced!(synced_at: Time.current)
        app.mark_teamtailor_full_sync_if_ready!(synced_at: Time.current)
      rescue => e
        Rails.logger.warn("TeamtailorDesyncCheckJob: Failed for app #{app.id}: #{e.message}")
      end
    end
  ensure
    release_lock
  end

  private

  def acquire_lock
    @lock_acquired = ActiveModel::Type::Boolean.new.cast(
      ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_KEY})")
    )

    return true if @lock_acquired

    Rails.logger.info("TeamtailorDesyncCheckJob skipped: lock held")
    false
  end

  def release_lock
    return unless @lock_acquired

    ActiveRecord::Base.connection.select_value("SELECT pg_advisory_unlock(#{LOCK_KEY})")
  ensure
    @lock_acquired = false
  end
end
