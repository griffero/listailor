class TeamtailorBackfillJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform
    service = Teamtailor::SyncService.new

    service.sync("jobs", full_sync: true)
    service.sync("candidates", full_sync: true)
    service.sync("applications", full_sync: true)
    service.sync("messages", full_sync: true)
  end
end
