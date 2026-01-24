module Teamtailor
  module Mappers
    class StageMapper
      SIMILARITY_THRESHOLD = 0.8

      def self.upsert!(payload)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        name = Utils.attr(attributes, "name") || "Imported stage #{teamtailor_id}"

        stage = PipelineStage.find_by(teamtailor_id: teamtailor_id)
        stage ||= match_by_name(name)

        if stage
          stage.teamtailor_id ||= teamtailor_id
          stage.name = name if rename_match?(stage.name, name)
        else
          stage = PipelineStage.new(
            name: name,
            position: (PipelineStage.maximum(:position) || -1) + 1
          )
          stage.teamtailor_id = teamtailor_id
        end

        kind = map_kind(attributes)
        stage.kind = kind if kind.present?

        stage.save!
        stage
      end

      def self.match_by_name(name)
        normalized = normalize_name(name)
        return nil if normalized.blank?

        stages = PipelineStage.all.to_a
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
    end
  end
end
