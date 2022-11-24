# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /routes', type: :request do
  let(:origin) { { lat: 3.1224467, long: 101.5884673, address: 'Ara Damansara' } }
  let(:jobs) do
    [
      { id: 'far', lat: 3.1660785, long: 101.6531737, address: 'Mont Kiara' },
      { id: 'near', lat: 3.1115114, long: 101.5861952, address: 'Jalan PJU 1a/4a' }
    ]
  end

  def post_route(body)
    post '/routes', params: body.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  context 'with valid locations' do
    before { stub_directions(leg_metres: [ 3_300, 14_000 ], waypoint_order: [ 0 ]) }

    it 'returns the driving distance and the stops nearest first' do
      post_route(origin: origin, jobs: jobs)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['total_driving_distance']).to eq 17_300
      expect(response.parsed_body['job_routes'].pluck('id')).to eq %w[near far]
      expect(response.parsed_body['job_routes'].first).to include('address' => 'Jalan PJU 1a/4a', 'distance_km' => 1.24)
    end

    it 'asks Google for a route from the origin to the farthest job' do
      post_route(origin: origin, jobs: jobs)

      expect(a_request(:get, DirectionsStub::DIRECTIONS_URL).with(query: hash_including(
        'origin' => '3.1224467,101.5884673',
        'destination' => '3.1660785,101.6531737',
        'waypoints' => 'optimize:true|3.1115114,101.5861952'
      ))).to have_been_made.once
    end
  end

  context 'with missing or invalid locations' do
    def expect_invalid(body, key)
      post_route(body)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to eq 'invalid_locations'
      expect(response.parsed_body['details']).to have_key(key)
      expect(a_request(:get, DirectionsStub::DIRECTIONS_URL)).not_to have_been_made
    end

    it('rejects a missing origin') { expect_invalid({ jobs: jobs }, 'origin') }
    it('rejects an origin that is not an object') { expect_invalid({ origin: 'home', jobs: jobs }, 'origin') }
    it('rejects missing jobs') { expect_invalid({ origin: origin }, 'jobs') }
    it('rejects an empty job list') { expect_invalid({ origin: origin, jobs: [] }, 'jobs') }
    it('rejects jobs that are not a list') { expect_invalid({ origin: origin, jobs: 'all' }, 'jobs') }

    it 'rejects more jobs than Google can route in one request' do
      expect_invalid({ origin: origin, jobs: Array.new(27) { jobs.first } }, 'jobs')
    end

    it 'names the job whose address is blank' do
      expect_invalid({ origin: origin, jobs: [ jobs.first, jobs.last.merge(address: ' ') ] }, 'jobs[1]')
      expect(response.parsed_body['details']['jobs[1]']).to eq [ "Address can't be blank" ]
    end

    it 'names the job without coordinates' do
      expect_invalid({ origin: origin, jobs: [ { address: 'Somewhere in KL' } ] }, 'jobs[0]')
      expect(response.parsed_body['details']['jobs[0]']).to include('Lat is not a number', 'Long is not a number')
    end

    it 'rejects an out-of-range origin latitude' do
      expect_invalid({ origin: origin.merge(lat: 123), jobs: jobs }, 'origin')
    end

    it 'rejects a job entry that is not an object' do
      expect_invalid({ origin: origin, jobs: [ jobs.first, 'Mont Kiara' ] }, 'jobs[1]')
    end
  end

  it 'answers 400 for a body that is not JSON' do
    post '/routes', params: '{"origin": ', headers: { 'Content-Type' => 'application/json' }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']).to eq 'invalid_json'
  end

  it 'passes Google errors through as JSON errors' do
    stub_directions(status: 'ZERO_RESULTS')

    post_route(origin: origin, jobs: jobs)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['error']).to eq 'route_not_found'
  end
end
