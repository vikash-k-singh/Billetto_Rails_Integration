class ApplicationController < ActionController::Base
  TOKEN_ERRORS = [
    JWT::DecodeError,
    JWT::ExpiredSignature,
    JWT::InvalidIatError,
    Clerk::Error,
    Clerk::ConfigurationError
  ].freeze

  CLERK_HANDSHAKE_PARAM = "__clerk_handshake"

  before_action :redirect_after_clerk_handshake
  before_action :set_current_user

  helper_method :current_user

  private

  def redirect_after_clerk_handshake
    return unless params[CLERK_HANDSHAKE_PARAM].present?

    redirect_to clerk_path_without_handshake
  end

  def clerk_path_without_handshake
    query = request.query_parameters.except(CLERK_HANDSHAKE_PARAM)
    return request.path if query.empty?

    "#{request.path}?#{query.to_query}"
  end

  def set_current_user
    @current_user = clerk_session_user
  end

  def current_user
    @current_user
  end

  def clerk_session_user
    token = session_token
    return nil if token.blank?

    payload = clerk_sdk.verify_token(token)
    user_id = payload && (payload["sub"] || payload[:sub])
    return nil if user_id.blank?

    CurrentUser.new(id: user_id)
  rescue *TOKEN_ERRORS => e
    Rails.logger.info("Clerk token rejected: #{e.class}")
    nil
  end

  def session_token
    cookies[:__session].presence ||
      request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip.presence
  end

  def clerk_sdk
    Clerk::SDK.new
  end

  def authenticate_user!
    return if current_user

    redirect_to root_path, alert: "You must be signed in to do that."
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
