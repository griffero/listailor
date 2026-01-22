class TeamtailorSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform
    service = Teamtailor::SyncService.new

    service.sync("jobs")
    service.sync("candidates")
    service.sync("applications")
    service.sync("messages")
  end
end
