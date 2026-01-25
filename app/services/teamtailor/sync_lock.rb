module Teamtailor
  class SyncLock
    def self.acquire(key, owner:, ttl:)
      now = Time.current

      lock = TeamtailorSyncLock.find_or_initialize_by(key: key)

      if lock.locked_at.present? && lock.locked_at > ttl.ago && lock.locked_by.present? && lock.locked_by != owner
        return false
      end

      lock.locked_by = owner
      lock.locked_at = now
      lock.heartbeat_at = now
      lock.save!
      true
    end

    def self.heartbeat(key, owner:)
      TeamtailorSyncLock.where(key: key, locked_by: owner)
                        .update_all(locked_at: Time.current, heartbeat_at: Time.current)
    end

    def self.release(key, owner:)
      TeamtailorSyncLock.where(key: key, locked_by: owner)
                        .update_all(locked_at: nil, heartbeat_at: nil)
    end
  end
end
