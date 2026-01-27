module App
  class BaseController < ApplicationController
    before_action :require_login

    # Inertia share common data
    inertia_share do
      {
        currentUser: current_user ? {
          id: current_user.id,
          email: current_user.email,
          role: current_user.role,
          canWrite: current_user.can_write?
        } : nil,
        flash: {
          notice: flash[:notice],
          alert: flash[:alert]
        }
      }
    end

    private

    def require_write_permission!
      return if current_user&.can_write?

      respond_to do |format|
        format.html { redirect_back fallback_location: app_dashboard_path, alert: "You don't have permission to perform this action" }
        format.json { render json: { error: "Permission denied" }, status: :forbidden }
      end
    end
  end
end
