# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

# Specs never talk to Google: a fixed fake key is substituted for the
# <GOOGLE_MAPS_API_KEY> placeholder when cassettes are replayed.
ENV['GOOGLE_API_KEY'] = 'test-google-api-key'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :none,
    # Compare decoded query parameters so URL-encoding differences between
    # HTTP clients do not break replay.
    match_requests_on: %i[method host path query]
  }

  # Cassettes are committed, so the key must never be written into one.
  config.filter_sensitive_data('<GOOGLE_MAPS_API_KEY>') { ENV['GOOGLE_API_KEY'] }
end
