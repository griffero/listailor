module App
  class PipelineStagesController < BaseController
    before_action :set_stage, only: [:update, :destroy]
    before_action :require_write_permission!

    def create
      @stage = PipelineStage.new(stage_params)
      @stage.position = PipelineStage.maximum(:position).to_i + 1

      if @stage.save
        redirect_to app_pipeline_path, notice: "Stage created"
      else
        redirect_to app_pipeline_path, alert: @stage.errors.full_messages.join(", ")
      end
    end

    def update
      if @stage.update(stage_params)
        redirect_to app_pipeline_path, notice: "Stage updated"
      else
        redirect_to app_pipeline_path, alert: @stage.errors.full_messages.join(", ")
      end
    end

    def destroy
      if @stage.applications.any?
        redirect_to app_pipeline_path, alert: "Cannot delete stage with applications. Move them first."
      else
        @stage.destroy
        redirect_to app_pipeline_path, notice: "Stage deleted"
      end
    end

    def reorder
      params[:stage_ids].each_with_index do |id, index|
        PipelineStage.where(id: id).update_all(position: index)
      end

      head :ok
    end

    private

    def set_stage
      @stage = PipelineStage.find(params[:id])
    end

    def stage_params
      params.require(:pipeline_stage).permit(:name, :kind)
    end
  end
end
