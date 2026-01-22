module App
  class QuestionsController < BaseController
    before_action :set_job
    before_action :set_question, only: [:update, :destroy]

    def create
      @question = @job.job_questions.build(question_params)

      if @question.save
        redirect_to edit_app_job_path(@job), notice: "Question added"
      else
        redirect_to edit_app_job_path(@job), alert: @question.errors.full_messages.join(", ")
      end
    end

    def update
      if @question.update(question_params)
        redirect_to edit_app_job_path(@job), notice: "Question updated"
      else
        redirect_to edit_app_job_path(@job), alert: @question.errors.full_messages.join(", ")
      end
    end

    def destroy
      @question.destroy
      redirect_to edit_app_job_path(@job), notice: "Question removed"
    end

    private

    def set_job
      @job = JobPosting.find(params[:job_id])
    end

    def set_question
      @question = @job.job_questions.find(params[:id])
    end

    def question_params
      params.require(:job_question).permit(:label, :kind, :required, :position, options: [])
    end
  end
end
