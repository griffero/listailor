class TeamtailorBackfillJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  LOCK_KEY = 972_654_321

  def perform
    return unless acquire_lock("backfill")

    Teamtailor::SyncService.new.backfill_all
  ensure
    release_lock
  end

  private

  def acquire_lock(label)
    @lock_acquired = ActiveModel::Type::Boolean.new.cast(
      ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_KEY})")
    )

    return true if @lock_acquired

    Rails.logger.info("Teamtailor #{label} skipped: lock held")
    false
  end

  def release_lock
    return unless @lock_acquired

    ActiveRecord::Base.connection.select_value("SELECT pg_advisory_unlock(#{LOCK_KEY})")
  ensure
    @lock_acquired = false
  end
end
