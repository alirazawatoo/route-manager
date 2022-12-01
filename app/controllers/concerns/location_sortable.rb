# frozen_string_literal: true

# Sorts location routes
module LocationSortable
  extend ActiveSupport::Concern

  def sort_route_locations(gogetter_location, job_locations)
    goget_lat_long = [gogetter_location[:lat], gogetter_location[:long]]
    job_routes = job_locations
    job_routes.each do |job_route|
      job_route.delete(:id)
      lat_long = [job_route[:lat], job_route[:long]]
      job_route[:distance] = Geocoder::Calculations.distance_between(goget_lat_long, lat_long).round(2)
    end

    job_routes.sort_by! { |route| route[:distance] }
  end
end
