class TeamtailorSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  LOCK_KEY = "teamtailor_sync"
  LOCK_TTL = 5.minutes

  def perform
    return unless acquire_lock("sync")

    service = Teamtailor::SyncService.new

    service.sync("applications")
    heartbeat_lock
    service.sync("jobs")
    heartbeat_lock
    service.sync("candidates")
    heartbeat_lock
    service.sync("messages")
  ensure
    release_lock
  end

  private

  def acquire_lock(label)
    # Use process.pid + thread.object_id to uniquely identify each worker thread
    owner = "#{label}-#{Process.pid}-#{Thread.current.object_id}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    lock = TeamtailorSyncLock.find_by(key: @lock_key)
    Rails.logger.info(
      "Teamtailor #{label} skipped: lock held (locked_by=#{lock&.locked_by}, locked_at=#{lock&.locked_at}, heartbeat_at=#{lock&.heartbeat_at})"
    )
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
