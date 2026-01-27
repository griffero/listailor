# frozen_string_literal: true

# Cloudflare R2 doesn't support AWS SDK's flexible checksums feature
# Configure AWS SDK to disable checksum validation for R2
Aws.config.update(
  request_checksum_calculation: "when_required",
  response_checksum_validation: "when_required"
)
