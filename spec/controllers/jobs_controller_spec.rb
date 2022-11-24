# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobsController, type: :controller do
  let(:last_route) { 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia' }
  let(:expected_failure_result) { { 'message' => 'Something went wrong' } }
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

    context 'when total distance is zero' do
      it 'expects output to be in JSON format and sorted array' do
        stub_directions(leg_metres: [ 0, 0, 0 ], waypoint_order: [ 0, 1 ])
        get :index
        expect(response.status).to eq 422
        expect(response.parsed_body).to eq expected_failure_result
      end
    end
  end
end
