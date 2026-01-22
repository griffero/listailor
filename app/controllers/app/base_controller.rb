module App
  class BaseController < ApplicationController
    before_action :require_login

    # Inertia share common data
    inertia_share do
      {
        currentUser: current_user ? { id: current_user.id, email: current_user.email } : nil,
        flash: {
          notice: flash[:notice],
          alert: flash[:alert]
        }
      }
    end
  end
end
