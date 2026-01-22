class RedirectController < ApplicationController
  def index
    if current_user
      redirect_to app_dashboard_path
    else
      redirect_to login_path
    end
  end
end
