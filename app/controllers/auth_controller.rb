class AuthController < ApplicationController
  layout "auth"

  def login
    redirect_to app_dashboard_path if logged_in?
  end

  def send_magic_link
    email = params[:email]&.downcase&.strip

    if email.blank?
      flash[:alert] = "Please enter your email address"
      redirect_to login_path
      return
    end

    # Only allow @fintoc.com emails
    unless email.end_with?("@fintoc.com")
      flash[:alert] = "Only @fintoc.com emails are allowed"
      redirect_to login_path
      return
    end

    # Auto-create user if doesn't exist
    user = User.find_or_create_by!(email: email) do |u|
      u.name = email.split("@").first.titleize
    end

    user.send_magic_link!
    flash[:notice] = "Check your email for the magic link!"

    redirect_to login_path
  end

  def verify_magic_link
    token = params[:token]
    user = User.find_by(magic_login_token: token)

    if user&.magic_link_valid?
      user.consume_magic_link!
      session[:user_id] = user.id
      flash[:notice] = "Welcome back!"
      redirect_to app_dashboard_path
    else
      flash[:alert] = "Invalid or expired magic link. Please request a new one."
      redirect_to login_path
    end
  end

  def logout
    session[:user_id] = nil
    flash[:notice] = "You've been logged out"
    redirect_to login_path
  end
end
