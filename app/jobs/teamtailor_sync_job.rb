class TeamtailorSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  LOCK_KEY = "teamtailor_sync"
  LOCK_TTL = 30.minutes

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
    owner = "#{label}-#{Process.pid}"
    @lock_owner = owner
    @lock_key = LOCK_KEY

    acquired = Teamtailor::SyncLock.acquire(@lock_key, owner: owner, ttl: LOCK_TTL)
    return true if acquired

    Rails.logger.info("Teamtailor #{label} skipped: lock held")
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
