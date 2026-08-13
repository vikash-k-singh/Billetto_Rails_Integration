class SessionsController < ApplicationController
  skip_before_action :redirect_after_clerk_handshake

  def destroy
    expire_clerk_cookies
    redirect_to root_path
  end

  private

  def expire_clerk_cookies
    request.cookies.each_key do |name|
      next unless clerk_session_cookie?(name.to_s)

      expire_cookie(name)
    end
  end

  def clerk_session_cookie?(name)
    name == Clerk::SESSION_COOKIE ||
      name == Clerk::CLIENT_UAT_COOKIE ||
      name.start_with?("__refresh_")
  end

  def expire_cookie(name)
    [ {}, { path: "/" }, { path: "/", domain: request.host } ].each do |options|
      cookies.delete(name, **options)
    end
  end
end
