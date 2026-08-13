module Billetto
  Error                   = Class.new(StandardError)
  AuthenticationError     = Class.new(Error)
  RateLimitError          = Class.new(Error)
  ApiError                = Class.new(Error)
  TimeoutError            = Class.new(Error)
  ConnectionError         = Class.new(Error)
  MalformedResponseError  = Class.new(Error)
end
