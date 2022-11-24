# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  config.configure_rspec_metadata!

  # Cassettes are committed, so the key must never be written into one.
  # A cassette recorded before this filter existed leaked a live billable key.
  config.filter_sensitive_data('<GOOGLE_MAPS_API_KEY>') { ENV['GOOGLE_API_KEY'] }
end
