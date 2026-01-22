module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!

      private

      def authenticate_api_token!
        token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")
        expected_token = ENV["N8N_API_TOKEN"]

        if expected_token.blank?
          render json: { error: "API not configured" }, status: :service_unavailable
          return
        end

        unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def render_validation_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
