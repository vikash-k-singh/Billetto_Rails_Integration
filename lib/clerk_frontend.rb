require "base64"

module ClerkFrontend
  CLERK_JS_VERSION = "5"

  def self.script_url
    host = frontend_host
    return if host.blank?

    "https://#{host}/npm/@clerk/clerk-js@#{CLERK_JS_VERSION}/dist/clerk.browser.js"
  end

  def self.frontend_host
    explicit = ENV["CLERK_FRONTEND_API"].presence
    return normalize_host(explicit) if explicit

    derive_host_from_publishable_key(ENV["CLERK_PUBLISHABLE_KEY"])
  end

  def self.normalize_host(value)
    value.to_s.strip.sub(%r{\Ahttps?://}i, "").delete_suffix("/")
  end

  def self.derive_host_from_publishable_key(key)
    encoded = key.to_s.split("_", 3).last
    return if encoded.blank?

    decoded = Base64.decode64(encoded)
    host = decoded.split("$").first.to_s.strip
    host if host.match?(/\A[a-z0-9][a-z0-9.-]+\.[a-z]{2,}\z/i)
  rescue ArgumentError
    nil
  end
end
