module Teamtailor
  class SyncService
    DEFAULT_RESOURCES = {
      "jobs" => "/jobs",
      "candidates" => "/candidates",
      "applications" => "/job-applications",
      "messages" => "/messages"
    }.freeze

    def initialize(client: Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    def sync(resource, full_sync: false)
      endpoint = resource_path(resource)
      state = TeamtailorSyncState.fetch(resource)
      last_synced_at = full_sync ? nil : state.last_synced_at
      max_seen_at = last_synced_at
      processed = 0

      params = {
        "page[size]" => 100,
        "sort" => "-updated-at"
      }

      begin
        @client.paginate(endpoint, params: params) do |response|
          included_index = Utils.index_included(response["included"])
          data = response["data"] || []

          stop = false

          data.each do |item|
            attributes = item.fetch("attributes", {})
            updated_at = Utils.parse_time(Utils.attr(attributes, "updated_at", "updated-at"))

            if last_synced_at.present? && updated_at.present? && updated_at < last_synced_at
              stop = true
              next
            end

            processed += 1
            max_seen_at = updated_at if updated_at.present? && (max_seen_at.blank? || updated_at > max_seen_at)

            case resource
            when "jobs"
              Mappers::JobPostingMapper.upsert!(item)
            when "candidates"
              Mappers::CandidateMapper.upsert!(item)
            when "applications"
              Mappers::ApplicationMapper.upsert!(item, included_index: included_index)
            when "messages"
              application = resolve_message_application(item)
              next if application.blank?

              Mappers::MessageMapper.upsert!(item, application: application)
            end
          end

          if stop
            update_state(state, max_seen_at)
            @logger.info("Teamtailor sync stopped early for #{resource} at #{max_seen_at}")
            :stop
          else
            update_state(state, max_seen_at)
          end
        end
      rescue RuntimeError => e
        if e.message.include?("404")
          @logger.warn("Teamtailor sync skipped for #{resource}: #{e.message}")
          return 0
        end
        raise
      end

      @logger.info("Teamtailor sync finished for #{resource}: #{processed} items")
      processed
    end

    def backfill_all
      RESOURCES.keys.each { |resource| sync(resource, full_sync: true) }
    end

    private

    def update_state(state, max_seen_at)
      state.update!(last_synced_at: max_seen_at || Time.current)
    end

    def resource_path(resource)
      env_key = "TEAMTAILOR_#{resource.upcase}_PATH"
      ENV.fetch(env_key, DEFAULT_RESOURCES.fetch(resource))
    end

    def resolve_message_application(payload)
      app_ref = payload.dig("relationships", "application", "data")
      teamtailor_id = app_ref&.fetch("id", nil)
      return nil if teamtailor_id.blank?

      Application.find_by(teamtailor_id: teamtailor_id)
    end
  end
end
