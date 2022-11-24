# frozen_string_literal: true

require 'rails_helper'

describe GoogleMapApi::CalculateDistanceService, type: :service do
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
    Timecop.freeze(Time.new(2022,06,19))
  end

  after do
    Timecop.return
  end

  context 'job routes are in sorted order', vcr: { record: :once } do
    it 'calculates total distance' do
      expect(described_class.new(job_routes, gogetter_location).call).to eq 338_00
    end
  end

  context 'job routes are empty' do
    it 'fails to calculate total distance' do
      expect(described_class.new([], gogetter_location).call).to be_nil
    end
  end
end
