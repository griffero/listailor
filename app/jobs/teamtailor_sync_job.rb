class TeamtailorSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  LOCK_KEY = "teamtailor_sync"
  LOCK_TTL = 30.minutes

  def perform
    return unless acquire_lock("sync")

    service = Teamtailor::SyncService.new

    service.sync("applications")
    service.sync("jobs")
    service.sync("candidates")
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
end
