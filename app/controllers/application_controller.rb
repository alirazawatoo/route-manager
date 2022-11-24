class ApplicationController < ActionController::API
  include LocationSortable

  DIRECTIONS_ERRORS = {
    GoogleMapApi::CalculateDistanceService::RouteNotFound =>
      [ :unprocessable_content, 'route_not_found', 'Google found no driving route between these locations.' ],
    GoogleMapApi::CalculateDistanceService::QuotaExceeded =>
      [ :service_unavailable, 'quota_exceeded', 'The Google Maps quota is used up. Try again later.' ],
    GoogleMapApi::CalculateDistanceService::RequestDenied =>
      [ :bad_gateway, 'request_denied', 'Google rejected the directions request. Check the API key and its Directions API access.' ],
    GoogleMapApi::CalculateDistanceService::TimedOut =>
      [ :gateway_timeout, 'directions_timeout', 'The Google Directions API did not answer in time. Try again.' ],
    GoogleMapApi::CalculateDistanceService::Unavailable =>
      [ :bad_gateway, 'directions_unavailable', 'The Google Directions API did not give a usable answer.' ]
  }.freeze

  rescue_from GoogleMapApi::CalculateDistanceService::Error, with: :render_directions_error
  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render json: { error: 'invalid_json', message: 'The request body is not valid JSON.' }, status: :bad_request
  end

  private

  def render_route(origin, jobs)
    job_routes = sort_route_locations(origin, jobs)
    route = GoogleMapApi::CalculateDistanceService.new(job_routes, origin).call
    render json: { total_driving_distance: route.total_distance, job_routes: route.job_routes }
  end

  def render_directions_error(error)
    status, code, message = DIRECTIONS_ERRORS.fetch(error.class)
    logger.warn("Directions request failed: #{error.class.name.demodulize}: #{error.message}")
    render json: { error: code, message: message }, status: status
  end
end
