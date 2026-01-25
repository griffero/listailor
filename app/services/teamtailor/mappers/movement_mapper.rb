module Teamtailor
  module Mappers
    class MovementMapper
      def self.upsert!(payload)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        
        # Resolve application
        app_ref = payload.dig("relationships", "job-application", "data")
        return nil if app_ref.blank?
        
        application = Application.find_by(teamtailor_id: app_ref["id"])
        return nil if application.blank?
        
        # Resolve stages
        from_stage_id = attributes["from-stage-id"]
        to_stage_id = attributes["to-stage-id"]
        return nil if to_stage_id.blank?
        
        from_stage = PipelineStage.find_by(teamtailor_id: from_stage_id) if from_stage_id.present?
        to_stage = PipelineStage.find_by(teamtailor_id: to_stage_id)
        return nil if to_stage.blank?
        
        # Parse date
        transitioned_at = Utils.parse_time(Utils.attr(attributes, "created_at", "created-at", "moved_at", "moved-at"))
        transitioned_at ||= Time.current
        
        # Find or create transition
        transition = ApplicationStageTransition
          .where(application: application)
          .where(to_stage: to_stage)
          .where("ABS(EXTRACT(EPOCH FROM (transitioned_at - ?))) < 5", transitioned_at)
          .first_or_initialize
        
        transition.from_stage = from_stage
        transition.transitioned_at = transitioned_at
        transition.save!
        
        transition
      end
    end
  end
end
