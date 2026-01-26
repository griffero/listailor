module Teamtailor
  class SyncService
    DEFAULT_RESOURCES = {
      "stages" => "/stages",
      "jobs" => ["/jobs", "/jobs?filter[status]=archived"],
      "candidates" => "/candidates",
      "applications" => ["/job-applications", "/applications"],
      "movements" => "/movements",
      "messages" => "/messages"
    }.freeze

    DEFAULT_INCLUDES = {
      "applications" => "job,candidate,stage",
      "jobs" => "questions,stages"
    }.freeze
    def initialize(client: Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    def sync(resource, full_sync: false)
      state = TeamtailorSyncState.fetch(resource)
      last_synced_at = full_sync ? nil : state.last_synced_at

      resource_paths(resource).each do |endpoint|
        result = sync_endpoint(endpoint, resource, state, last_synced_at, full_sync: full_sync)
        return result unless result == :not_found
      end

      @logger.warn("Teamtailor sync skipped for #{resource}: all endpoints returned 404")
      0
    end

    def backfill_all
      DEFAULT_RESOURCES.keys.each { |resource| sync(resource, full_sync: true) }
    end

    private

    def update_state(state, max_seen_at)
      state.update!(last_synced_at: max_seen_at || Time.current)
    end

    def resource_paths(resource)
      env_key = "TEAMTAILOR_#{resource.upcase}_PATH"
      env_value = ENV[env_key]
      return [env_value] if env_value.present?

      value = DEFAULT_RESOURCES.fetch(resource)
      value.is_a?(Array) ? value : [value]
    end

    def sync_endpoint(endpoint, resource, state, last_synced_at, full_sync: false)
      max_seen_at = last_synced_at
      processed = 0
      seen_stage_ids = []

      params = {
        "page[size]" => page_size_for(resource)
      }
      sort_param = sort_for(resource)
      params["sort"] = sort_param if sort_param.present?
      include_param = includes_for(resource)
      params["include"] = include_param if include_param.present?

      begin
        @client.paginate(endpoint, params: params) do |response|
          included_index = Utils.index_included(response["included"])
          data = response["data"] || []

          stop = false

          data.each do |item|
            next if item.blank?

            attributes = item.fetch("attributes", {})
            updated_at = Utils.parse_time(Utils.attr(attributes, "updated_at", "updated-at"))

            if !full_sync && sort_param.present? && last_synced_at.present? && updated_at.present? && updated_at < last_synced_at
              stop = true
              next
            end

            processed += 1
            max_seen_at = updated_at if updated_at.present? && (max_seen_at.blank? || updated_at > max_seen_at)

            case resource
            when "stages"
              stage = Mappers::StageMapper.upsert!(item)
              seen_stage_ids << stage.teamtailor_id if stage&.teamtailor_id.present?
            when "jobs"
              Mappers::JobPostingMapper.upsert!(item, included_index: included_index)
            when "candidates"
              Mappers::CandidateMapper.upsert!(item)
            when "applications"
              # Default to skipping answers in regular sync - use backfill jobs for answers
              skip_answers = ENV.fetch("TEAMTAILOR_SKIP_ANSWERS", "true") != "false"
              Mappers::ApplicationMapper.upsert!(item, included_index: included_index, client: @client, skip_answers: skip_answers)
            when "movements"
              Mappers::MovementMapper.upsert!(item)
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
        return :not_found if e.message.include?("404")
        raise
      end

      if resource == "stages" && full_sync
        Mappers::StageMapper.prune_missing!(seen_stage_ids)
      end

      @logger.info("Teamtailor sync finished for #{resource}: #{processed} items")
      processed
    end

    def includes_for(resource)
      env_key = "TEAMTAILOR_#{resource.upcase}_INCLUDE"
      ENV.fetch(env_key, DEFAULT_INCLUDES[resource])
    end

    def sort_for(resource)
      env_key = "TEAMTAILOR_#{resource.upcase}_SORT"
      ENV.fetch(env_key, nil)
    end

    def page_size_for(resource)
      env_key = "TEAMTAILOR_#{resource.upcase}_PAGE_SIZE"
      env_value = ENV[env_key].presence
      return env_value.to_i if env_value.present?

      ENV.fetch("TEAMTAILOR_PAGE_SIZE", "25").to_i
    end

    def resolve_message_application(payload)
      app_ref = payload.dig("relationships", "application", "data")
      teamtailor_id = app_ref&.fetch("id", nil)
      return nil if teamtailor_id.blank?

      Application.find_by(teamtailor_id: teamtailor_id)
    end
  end
end
