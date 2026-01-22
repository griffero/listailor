module Embed
  class BaseController < ApplicationController
    layout "embed"

    skip_before_action :verify_authenticity_token, only: [:create]
    before_action :set_iframe_headers

    private

    def set_iframe_headers
      allowed_origins = Setting.embed_allowed_origins

      if allowed_origins.any?
        # Set frame-ancestors for CSP
        response.headers["Content-Security-Policy"] = "frame-ancestors 'self' #{allowed_origins.join(' ')}"
        response.headers["X-Frame-Options"] = "ALLOWALL"
      else
        # Allow from any origin in development
        response.headers["Content-Security-Policy"] = "frame-ancestors *"
        response.headers["X-Frame-Options"] = "ALLOWALL"
      end

      # Allow credentials for forms
      response.headers["Access-Control-Allow-Credentials"] = "true"
    end
  end
end
