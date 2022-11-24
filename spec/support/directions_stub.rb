# frozen_string_literal: true

# Builds canned Google Directions responses for WebMock, so error and edge
# cases can be exercised without a recorded cassette.
module DirectionsStub
  DIRECTIONS_URL = %r{\Ahttps://maps\.googleapis\.com/maps/api/directions/json}

  def stub_directions(status: 'OK', leg_metres: [], waypoint_order: [])
    body = {
      status: status,
      routes: leg_metres.empty? ? [] : [ { waypoint_order: waypoint_order,
                                           legs: leg_metres.map { |m| { distance: { value: m } } } } ]
    }
    stub_request(:get, DIRECTIONS_URL)
      .to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json; charset=UTF-8' })
  end
end

RSpec.configure { |config| config.include DirectionsStub }
