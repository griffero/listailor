module Teamtailor
  module Mappers
    class StageMapper
      SIMILARITY_THRESHOLD = 0.8

      def self.upsert!(payload, job_posting: nil)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        name = Utils.attr(attributes, "name") || "Imported stage #{teamtailor_id}"

        # Try to find existing stage by teamtailor_id + job_posting
        stage = if job_posting
          PipelineStage.find_by(teamtailor_id: teamtailor_id, job_posting_id: job_posting.id)
        else
          PipelineStage.find_by(teamtailor_id: teamtailor_id, job_posting_id: nil)
        end
        
        stage ||= match_by_name(name, job_posting: job_posting)

        if stage
          stage.teamtailor_id ||= teamtailor_id
          stage.job_posting ||= job_posting
          stage.name = name if rename_match?(stage.name, name)
        else
          max_position = if job_posting
            PipelineStage.where(job_posting: job_posting).maximum(:position) || -1
          else
            PipelineStage.where(job_posting_id: nil).maximum(:position) || -1
          end
          
          stage = PipelineStage.new(
            name: name,
            job_posting: job_posting,
            position: max_position + 1,
            teamtailor_id: teamtailor_id
          )
        end

        kind = map_kind(attributes)
        stage.kind = kind if kind.present?

        stage.save!
        stage
      end

      def self.match_by_name(name, job_posting: nil)
        normalized = normalize_name(name)
        return nil if normalized.blank?

        stages = if job_posting
          PipelineStage.where(job_posting: job_posting).to_a
        else
          PipelineStage.where(job_posting_id: nil).to_a
        end
        
        return nil if stages.empty?
        
        exact = stages.find { |stage| normalize_name(stage.name) == normalized }
        return exact if exact

        tokens = normalized.split
        best = stages.max_by do |stage|
          similarity_score(tokens, normalize_name(stage.name).split)
        end

        return nil unless best

        score = similarity_score(tokens, normalize_name(best.name).split)
        score >= SIMILARITY_THRESHOLD ? best : nil
      end

      def self.rename_match?(existing_name, incoming_name)
        normalize_name(existing_name) != normalize_name(incoming_name)
      end

      def self.normalize_name(name)
        name.to_s.downcase.strip.gsub(/[^a-z0-9\s]/, " ").squeeze(" ").strip
      end

      def self.similarity_score(tokens_a, tokens_b)
        return 0.0 if tokens_a.empty? || tokens_b.empty?

        intersection = tokens_a & tokens_b
        intersection.size.to_f / [tokens_a.size, tokens_b.size].max
      end

      def self.map_kind(attributes)
        legacy = Utils.attr(attributes, "legacy_stage_type_name", "legacy-stage-type-name")
        name = Utils.attr(attributes, "name")
        value = [legacy, name].compact.join(" ").downcase

        return "hired" if value.include?("hired")
        return "rejected" if value.include?("rejected")

        "active"
      end

    def self.prune_missing!(teamtailor_ids, job_posting: nil)
      ids = Array(teamtailor_ids).compact.uniq
      
      # Build scope for stages to prune
      scope = if job_posting
        # For job-specific sync, prune stages of this job that aren't in the list
        PipelineStage.where(job_posting: job_posting)
                     .where.not(teamtailor_id: ids)
      else
        # For global sync, prune global stages not in Teamtailor
        PipelineStage.where(job_posting_id: nil)
                     .where("teamtailor_id IS NULL OR teamtailor_id NOT IN (?)", ids.presence || [""])
      end

      return if scope.none?

      stage_ids = scope.pluck(:id)

      Application.where(current_stage_id: stage_ids).update_all(current_stage_id: nil)
      ApplicationStageTransition.where(from_stage_id: stage_ids).delete_all
      ApplicationStageTransition.where(to_stage_id: stage_ids).delete_all
      PipelineStage.where(id: stage_ids).delete_all
    end
    end
  end
end
