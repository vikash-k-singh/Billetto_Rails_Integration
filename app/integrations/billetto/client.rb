module Billetto
  class Client
    BASE_URL = 'https://billetto.dk/api/v3'

    def initialize(
      access_key_id:     ENV.fetch('BILLETTO_ACCESS_KEY_ID'),
      access_key_secret: ENV.fetch('BILLETTO_ACCESS_KEY_SECRET')
    )
      @access_key_id     = access_key_id
      @access_key_secret = access_key_secret
    end

    def list_events(after: nil, limit: 25)
      params = { limit: limit }
      params[:after] = after if after

      response = connection.get('/api/v3/public/events', params)
      handle_response(response)
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers['Api-Keypair'] = "#{@access_key_id}:#{@access_key_secret}"
        f.headers['Accept']      = 'application/json'
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299 then response.body
      when 401      then raise AuthenticationError, 'Invalid API credentials'
      when 429      then raise RateLimitError, 'Rate limit exceeded'
      else               raise ApiError, "Unexpected API response: #{response.status}"
      end
    end
  end
end