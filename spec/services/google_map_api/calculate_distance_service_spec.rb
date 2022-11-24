# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleMapApi::CalculateDistanceService, type: :service do
  let(:gogetter_location) do
    {
      id: 0,
      lat: 3.1224467,
      long: 101.5884673,
      address: 'PD1-11-02, Maisson Residence, Jalan PJU 1a/3, Ara Damansara, 47301 Petaling Jaya, Selangor, Malaysia'
    }
  end

  let(:job_routes) do
    [
      {
        lat: 3.1115114,
        long: 101.5861952,
        address: '1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia',
        distance: 0.77
      },
      {
        lat: 3.0716104,
        long: 101.6055764,
        address: '1, Jalan PJS 11/15, Bandar Sunway, 46150 Petaling Jaya, Selangor, Malaysia',
        distance: 3.71
      },
      {
        lat: 3.1660785,
        long: 101.6531737,
        address: 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia',
        distance: 5.39
      }
    ]
  end

  before do
    # departure_time is part of the recorded request URI, so freeze at the
    # exact instant the cassettes were recorded, independent of the host TZ.
    Timecop.freeze(Time.at(1_655_578_800))
  end

  context 'job routes are in sorted order', :vcr do
    it 'calculates total distance' do
      expect(described_class.new(job_routes, gogetter_location).call.total_distance).to eq 338_00
    end
  end

  context 'job routes are empty' do
    it 'fails to calculate total distance' do
      expect(described_class.new([], gogetter_location).call).to be_nil
    end
  end

  context 'when Google reorders the waypoints' do
    it 'returns the stops in the order Google drove, destination last' do
      stub_directions(leg_metres: [ 8_000, 3_000, 22_000 ], waypoint_order: [ 1, 0 ])

      route = described_class.new(job_routes, gogetter_location).call

      expect(route.job_routes).to eq [ job_routes[1], job_routes[0], job_routes[2] ]
      expect(route.total_distance).to eq 33_000
    end

    it 'keeps the requested order when waypoint_order is missing or malformed' do
      stub_directions(leg_metres: [ 1, 2, 3 ], waypoint_order: [ 0 ])

      expect(described_class.new(job_routes, gogetter_location).call.job_routes).to eq job_routes
    end
  end

  describe 'Google error responses' do
    subject(:call) { described_class.new(job_routes, gogetter_location).call }

    {
      'ZERO_RESULTS' => described_class::RouteNotFound,
      'NOT_FOUND' => described_class::RouteNotFound,
      'OVER_QUERY_LIMIT' => described_class::QuotaExceeded,
      'OVER_DAILY_LIMIT' => described_class::QuotaExceeded,
      'REQUEST_DENIED' => described_class::RequestDenied,
      'INVALID_REQUEST' => described_class::RequestDenied,
      'UNKNOWN_ERROR' => described_class::Unavailable
    }.each do |status, error_class|
      it "raises #{error_class.name.demodulize} for #{status}" do
        stub_directions(status: status)
        expect { call }.to raise_error(error_class, /#{status}/)
      end
    end

    it 'treats OK without any route as no route found' do
      stub_directions(status: 'OK')
      expect { call }.to raise_error(described_class::RouteNotFound)
    end

    it 'raises Unavailable on an HTTP error from Google' do
      stub_request(:get, DirectionsStub::DIRECTIONS_URL).to_return(status: 500, body: 'Internal error')
      expect { call }.to raise_error(described_class::Unavailable, /HTTP 500/)
    end

    it 'raises Unavailable when the body is not JSON' do
      stub_request(:get, DirectionsStub::DIRECTIONS_URL)
        .to_return(status: 200, body: '{"routes": [', headers: { 'Content-Type' => 'application/json' })
      expect { call }.to raise_error(described_class::Unavailable, /malformed JSON/)
    end

    it 'never sends a request without an API key' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('GOOGLE_API_KEY').and_raise(KeyError)
      expect { call }.to raise_error(KeyError)
      expect(a_request(:get, DirectionsStub::DIRECTIONS_URL)).not_to have_been_made
    end
  end

  describe 'slow or unreachable Google' do
    subject(:call) { described_class.new(job_routes, gogetter_location).call }

    it 'raises TimedOut when the connection times out' do
      stub_request(:get, DirectionsStub::DIRECTIONS_URL).to_timeout
      expect { call }.to raise_error(described_class::TimedOut, /within 5.0s/)
    end

    it 'raises TimedOut when the response is not read in time' do
      stub_request(:get, DirectionsStub::DIRECTIONS_URL).to_raise(Net::ReadTimeout)
      expect { call }.to raise_error(described_class::TimedOut)
    end

    it 'raises Unavailable when Google cannot be reached' do
      stub_request(:get, DirectionsStub::DIRECTIONS_URL).to_raise(SocketError)
      expect { call }.to raise_error(described_class::Unavailable, /SocketError/)
    end

    it 'bounds every request with a timeout' do
      stub_directions(leg_metres: [ 1, 2, 3 ], waypoint_order: [ 0, 1 ])
      allow(HTTParty).to receive(:get).and_call_original

      call

      expect(HTTParty).to have_received(:get).with(described_class::DEFAULT_DIRECTIONS_URL, hash_including(timeout: 5.0))
    end

    it 'sends requests to GOOGLE_DIRECTIONS_URL when it is set' do
      stub_request(:get, %r{\Ahttp://directions-stub:9000/directions}).to_return(
        headers: { 'Content-Type' => 'application/json' },
        body: { status: 'OK', routes: [ { waypoint_order: [ 0, 1 ], legs: [ { distance: { value: 10 } } ] * 3 } ] }.to_json
      )
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('GOOGLE_DIRECTIONS_URL', anything).and_return('http://directions-stub:9000/directions')

      expect(call.total_distance).to eq 30
    end

    it 'reads the timeout from GOOGLE_MAPS_TIMEOUT_SECONDS' do
      stub_directions(leg_metres: [ 1, 2, 3 ], waypoint_order: [ 0, 1 ])
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('GOOGLE_MAPS_TIMEOUT_SECONDS', anything).and_return('1.5')
      allow(HTTParty).to receive(:get).and_call_original

      call

      expect(HTTParty).to have_received(:get).with(anything, hash_including(timeout: 1.5))
    end
  end
end
