class JobsController < ApplicationController
  GOOGLE_API_KEY= 'AIzaSyBdcqjL5LQaeAG_4nGbuaL3aYcUnTq_pJY'
  
  def index

    @gogetter_location = {:id=>0, :lat=>3.1224467, :long=>101.5884673, :address=> 'PD1-11-02, Maisson Residence, Jalan PJU 1a/3, Ara Damansara, 47301 Petaling Jaya, Selangor, Malaysia'}

    @job_locations = [{:id=>1, :lat=>3.0716104, :long=>101.6055764, :address=> '1, Jalan PJS 11/15, Bandar Sunway, 46150 Petaling Jaya, Selangor, Malaysia'}, {:id=>2, :lat=>3.1115114, :long=>101.5861952, :address=> '1673, Jalan PJU 1a/4a, 47310 Petaling Jaya, Selangor, Malaysia'}, {:id=>3, :lat=>3.1660785, :long=>101.6531737, :address=> 'L1-02, 1 Mont Kiara Mall, Jalan Kiara, Mont Kiara, 50480 Kuala Lumpur, Malaysia'}]

    #using Geocoder gem, get an array object of all the job_locations ordered by the closest to the farthest from the gogetter. Look at the sample `expected_result_json["job_routes"]` in spec/controllers/jobs_controller_spec.rb as an indication of how the array object should look like.
    job_routes = 

    #Gogetter has decided to take all three jobs in the same sorted order and go to all the locations. We want to get the total driving distance for the gogetter to complete all the jobs. the following code below gets the total_distance
    temp_response = nil
    final_destination = nil

    final_destination = job_routes.last
    remaining_destinations = job_routes
    remaining_destinations.delete(final_destination)
      
    directions_uri = "https://maps.googleapis.com/maps/api/directions/json?mode=driving&departure_time=#{Time.now.to_i}&traffic_model=best_guess&key=#{GOOGLE_API_KEY}"
    directions_uri += "&origin=#{@gogetter_location[:lat]},#{@gogetter_location[:long]}"
    directions_uri += "&destination=#{final_destination[:lat]},#{final_destination[:long]}"


    unless remaining_destinations.blank?
      directions_uri += "&waypoints=optimize:true"
      remaining_destinations.each do |temp_destination|
        directions_uri += "|#{temp_destination[:lat]},#{temp_destination[:long]}"
      end
    end
      
    temp_response = HTTParty.get(URI.encode(directions_uri))

    temp_distance = 0
    temp_response["routes"][0]["legs"].count.times do |a|
      temp_distance += temp_response["routes"][0]["legs"][a]["distance"]["value"]
    end
    total_driving_distance = temp_distance
  end
end