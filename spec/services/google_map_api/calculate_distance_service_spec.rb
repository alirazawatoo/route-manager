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
end
