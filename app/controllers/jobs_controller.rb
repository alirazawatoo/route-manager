# frozen_string_literal: true

# Plans the route for a fixed sample of Kuala Lumpur jobs. POST /routes
# does the same for locations sent by the client.
class JobsController < ApplicationController
  before_action :set_gogetter_location, only: :index
  before_action :set_job_locations, only: :index

  def index
    render_route(@gogetter_location, @job_locations)
  end

  private

  def set_gogetter_location
    @gogetter_location = {
      id: 0,
      lat: 3.1224467,
      long: 101.5884673,
      address: 'PD1-11-02, Maisson Residence, Jalan PJU 1a/3, Ara Damansara, 47301 Petaling Jaya, Selangor, Malaysia'
    }
  end

  def set_job_locations
    @job_locations = [
      { id: 1, lat: 3.0716104, long: 101.6055764,
        address: '1, Jalan PJS 11/15, Bandar Sunway, 46150 Petaling Jaya, Selangor, Malaysia' },
      { id: 2, lat: 3.1115114, long: 101.5861952,
        address: '1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia' },
      { id: 3, lat: 3.1660785, long: 101.6531737,
        address: 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia' }
    ]
  end
end
