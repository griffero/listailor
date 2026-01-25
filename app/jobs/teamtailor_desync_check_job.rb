class TeamtailorDesyncCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  LOCK_KEY = "teamtailor_desync_check"
  LOCK_TTL = 10.minutes
  BATCH_SIZE = 50

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
        heartbeat_lock if (app.id % 10).zero?
      rescue => e
        Rails.logger.warn("TeamtailorDesyncCheckJob: Failed for app #{app.id}: #{e.message}")
      end
    end
  ensure
    release_lock
  end

  private

  def acquire_lock
    owner = "desync-check-#{Process.pid}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    Rails.logger.info("TeamtailorDesyncCheckJob skipped: lock held")
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
