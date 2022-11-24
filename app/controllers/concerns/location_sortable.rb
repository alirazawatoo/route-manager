# frozen_string_literal: true

# Orders job stops by straight-line distance from the gogetter. The farthest
# stop becomes the route's destination; Google is left to optimise the order
# of the stops in between.
module LocationSortable
  extend ActiveSupport::Concern

  def sort_route_locations(gogetter_location, job_locations)
    origin = gogetter_location.values_at(:lat, :long)

    job_locations
      .map do |job|
        distance = Geocoder::Calculations.distance_between(origin, job.values_at(:lat, :long), units: :km)
        job.merge(distance_km: distance.round(2))
      end
      .sort_by { |job| [ job[:distance_km], job[:id].to_s ] }
  end
end
