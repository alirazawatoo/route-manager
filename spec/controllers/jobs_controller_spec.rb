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
            "lat":3.1115114,
            "long":101.5861952,
            "address":"1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia",
            "distance":0.77
          },
          {
            "lat":3.0716104,
            "long":101.6055764,
            "address":"1, Jalan PJS 11/15, Bandar Sunway, 46150 Petaling Jaya, Selangor, Malaysia",
            "distance":3.71
          },
          {
            "lat":3.1660785,
            "long":101.6531737,
            "address":"L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia",
            "distance":5.39
          }
        ]
      }
    JSON
  end

  before do
    Timecop.freeze(Time.new(2022,06,19))
  end

  after do
    Timecop.return
  end

  describe 'GET #index', vcr: { record: :once } do
    context 'when total distance is positive' do
      before(:each) { get :index }

      it 'expects output to be in JSON format and sorted array' do
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq JSON.parse(expected_result_json)
      end
      it 'expects the last job to be Mont Kiara address' do
        expect(JSON.parse(response.body)['job_routes'].last['address']).to eq last_route
      end
    end

    context 'when total distance is zero' do
      it 'expects output to be in JSON format and sorted array' do
        allow_any_instance_of(GoogleMapApi::CalculateDistanceService).to receive(:call).and_return(0)
        get :index
        expect(response.status).to eq 422
        expect(JSON.parse(response.body)).to eq expected_failure_result
      end
    end
  end
end
