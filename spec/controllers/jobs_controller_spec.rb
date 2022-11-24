# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobsController, type: :controller do
  let(:last_route) { 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia' }
  let(:expected_result_json) do
    <<-JSON
      {
        "total_driving_distance":33800,
        "job_routes":[
          {
            "id":2,
            "lat":3.1115114,
            "long":101.5861952,
            "address":"1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia",
            "distance_km":1.24
          },
          {
            "id":1,
            "lat":3.0716104,
            "long":101.6055764,
            "address":"1, Jalan PJS 11/15, Bandar Sunway, 46150 Petaling Jaya, Selangor, Malaysia",
            "distance_km":5.96
          },
          {
            "id":3,
            "lat":3.1660785,
            "long":101.6531737,
            "address":"L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia",
            "distance_km":8.67
          }
        ]
      }
    JSON
  end

  before do
    # departure_time is part of the recorded request URI, so freeze at the
    # exact instant the cassettes were recorded, independent of the host TZ.
    Timecop.freeze(Time.at(1_655_578_800))
  end

  describe 'GET #index', :vcr do
    context 'when total distance is positive' do
      before { get :index }

      it 'expects output to be in JSON format and sorted array' do
        expect(response.status).to eq 200
        expect(response.parsed_body).to eq JSON.parse(expected_result_json)
      end

      it 'expects the last job to be Mont Kiara address' do
        expect(response.parsed_body['job_routes'].last['address']).to eq last_route
      end
    end

    context 'when every stop is at the starting point' do
      it 'returns a zero driving distance instead of an error' do
        stub_directions(leg_metres: [ 0, 0, 0 ], waypoint_order: [ 0, 1 ])
        get :index
        expect(response.status).to eq 200
        expect(response.parsed_body['total_driving_distance']).to eq 0
      end
    end

    {
      'ZERO_RESULTS' => [ 422, 'route_not_found' ],
      'NOT_FOUND' => [ 422, 'route_not_found' ],
      'OVER_QUERY_LIMIT' => [ 503, 'quota_exceeded' ],
      'REQUEST_DENIED' => [ 502, 'request_denied' ],
      'INVALID_REQUEST' => [ 502, 'request_denied' ],
      'UNKNOWN_ERROR' => [ 502, 'directions_unavailable' ]
    }.each do |google_status, (http_status, error_code)|
      context "when Google answers #{google_status}" do
        it "responds #{http_status} with error #{error_code}" do
          stub_directions(status: google_status)
          get :index
          expect(response.status).to eq http_status
          expect(response.parsed_body).to include('error' => error_code, 'message' => a_kind_of(String))
        end
      end
    end
  end
end
