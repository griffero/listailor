require "httparty"

module Teamtailor
  class Client
    include HTTParty

    DEFAULT_BASE_URL = "https://api.teamtailor.com/v1".freeze
    DEFAULT_API_VERSION = "20240904".freeze
    USER_AGENT = "Listailor-ATS/1.0".freeze
    MAX_RETRIES = 5

    def initialize(
      api_key: ENV["TEAMTAILOR_API_KEY"],
      base_url: ENV["TEAMTAILOR_API_BASE_URL"],
      api_version: ENV["TEAMTAILOR_API_VERSION"]
    )
      @api_key = api_key
      @base_url = base_url.presence || DEFAULT_BASE_URL
      @api_version = api_version.presence || DEFAULT_API_VERSION
      raise "TEAMTAILOR_API_KEY is missing" if @api_key.blank?
    end

    def get(path, params: {})
      request_with_retry(:get, path, params: params)
    end

    def paginate(path, params: {})
      next_url = build_url(path)
      current_params = params

      while next_url.present?
        response = request_with_retry(:get, next_url, params: current_params, absolute: true)
        result = block_given? ? yield(response) : nil
        break if result == :stop

        next_url = response.dig("links", "next")
        current_params = {}
      end
    end

    private

    def request_with_retry(method, path, params:, absolute: false)
      retries = 0

      begin
        response = self.class.send(
          method,
          absolute ? path : build_url(path),
          headers: headers,
          query: params,
          timeout: 30
        )

        if response.code == 429
          sleep retry_sleep(retries)
          retries += 1
          raise "rate limited"
        end

        unless response.success?
          raise "Teamtailor request failed: #{response.code} - #{response.body}"
        end

        response.parsed_response
      rescue StandardError
        raise if retries >= MAX_RETRIES

        sleep retry_sleep(retries)
        retries += 1
        retry
      end
    end

    def headers
      {
        "Authorization" => "Token token=#{@api_key}",
        "X-Api-Version" => @api_version,
        "Content-Type" => "application/json",
        "User-Agent" => USER_AGENT
      }
    end

    def build_url(path)
      return path if path.to_s.start_with?("http://", "https://")
      "#{@base_url}/#{path.to_s.delete_prefix("/")}"
    end

    def retry_sleep(retry_count)
      base = 2**retry_count
      rand(base..(base + 1))
    end
  end
end
