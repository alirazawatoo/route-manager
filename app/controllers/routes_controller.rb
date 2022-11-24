# frozen_string_literal: true

# Plans a route for locations supplied by the client.
class RoutesController < ApplicationController
  LOCATION_FIELDS = %i[id lat long address].freeze

  def create
    route_request = RouteRequest.new(origin: location_attributes(params[:origin]), jobs: job_attributes)
    unless route_request.valid?
      return render json: { error: 'invalid_locations', details: route_request.problems }, status: :unprocessable_content
    end

    render_route(route_request.origin_location, route_request.job_locations)
  end

  private

  def job_attributes
    jobs = params[:jobs]
    jobs.is_a?(Array) ? jobs.map { |job| location_attributes(job) } : jobs
  end

  # Anything that is not a JSON object is passed through untouched so that
  # RouteRequest can say what was wrong with it.
  def location_attributes(value)
    value.is_a?(ActionController::Parameters) ? value.permit(*LOCATION_FIELDS).to_h.symbolize_keys : value
  end
end
