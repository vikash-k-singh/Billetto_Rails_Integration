class ApplicationController < ActionController::Base
  before_action :set_current_user

  helper_method :current_user

  private

  def set_current_user
    @current_user = clerk_session_user
  end

  def current_user
    @current_user
  end

  def clerk_session_user
    token = cookies[:__session] ||
            request.headers['Authorization']&.delete_prefix('Bearer ')
    return nil unless token.present?

    payload = Clerk::SDK.new.verify_token(token)
    OpenStruct.new(id: payload['sub'])
  rescue StandardError
    nil
  end

  def authenticate_user!
    redirect_to root_path, alert: 'You must be signed in to do that.' unless current_user
  end

  def command_bus
    Rails.configuration.command_bus
  end
end