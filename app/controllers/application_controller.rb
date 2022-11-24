class ApplicationController < ActionController::API
  DIRECTIONS_ERRORS = {
    GoogleMapApi::CalculateDistanceService::RouteNotFound =>
      [ :unprocessable_content, 'route_not_found', 'Google found no driving route between these locations.' ],
    GoogleMapApi::CalculateDistanceService::QuotaExceeded =>
      [ :service_unavailable, 'quota_exceeded', 'The Google Maps quota is used up. Try again later.' ],
    GoogleMapApi::CalculateDistanceService::RequestDenied =>
      [ :bad_gateway, 'request_denied', 'Google rejected the directions request. Check the API key and its Directions API access.' ],
    GoogleMapApi::CalculateDistanceService::Unavailable =>
      [ :bad_gateway, 'directions_unavailable', 'The Google Directions API did not give a usable answer.' ]
  }.freeze

  rescue_from GoogleMapApi::CalculateDistanceService::Error, with: :render_directions_error

  private

  def render_directions_error(error)
    status, code, message = DIRECTIONS_ERRORS.fetch(error.class)
    logger.warn("Directions request failed: #{error.class.name.demodulize}: #{error.message}")
    render json: { error: code, message: message }, status: status
  end
end
