module App
  class GlobalQuestionsController < BaseController
    before_action :set_question, only: [:update, :destroy]

    def create
      @question = GlobalQuestion.new(question_params)

      if @question.save
        redirect_to app_settings_path, notice: "Global question added"
      else
        redirect_to app_settings_path, alert: @question.errors.full_messages.join(", ")
      end
    end

    def update
      if @question.update(question_params)
        redirect_to app_settings_path, notice: "Global question updated"
      else
        redirect_to app_settings_path, alert: @question.errors.full_messages.join(", ")
      end
    end

    def destroy
      @question.destroy
      redirect_to app_settings_path, notice: "Global question removed"
    end

    private

    def set_question
      @question = GlobalQuestion.find(params[:id])
    end

    def question_params
      params.require(:global_question).permit(:label, :kind, :required, :position, options: [])
    end
  end
end
