require 'rails_helper'

RSpec.describe JobsController, :type => :controller do
  let(:expected_result_json) {
    <<-JSON
      {
        total_driving_distance: 33281,
        job_routes: [
          {
            lat: 3.1115114,
            long: 101.5861952,
            address: '1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia',
            distance_: 0.78
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
      }
    JSON
  }

  describe 'POST #create' do
    it "expects output to be in JSON format" do
      expect(result).to eq JSON.load(expected_result_json)
    end

    it "expects the last job to be Mont Kiara address"
      expect(result["jobs"].last["address"]).to eq 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia'
    end
  end
end