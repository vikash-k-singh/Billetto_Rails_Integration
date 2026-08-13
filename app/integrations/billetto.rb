module Billetto
  Error               = Class.new(StandardError)
  AuthenticationError = Class.new(Error)
  RateLimitError      = Class.new(Error)
  ApiError            = Class.new(Error)
end