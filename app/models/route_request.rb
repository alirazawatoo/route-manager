# frozen_string_literal: true

# The body of POST /routes: one starting point and the jobs to visit.
class RouteRequest
  # Google Directions accepts 25 waypoints plus the destination.
  MAX_JOBS = 26

  attr_reader :origin, :jobs, :problems

  def initialize(origin:, jobs:)
    @origin = origin
    @jobs = jobs
    @problems = {}
  end

  def valid?
    @problems = {}
    check_location('origin', origin)
    if !jobs.is_a?(Array) || jobs.empty?
      problems['jobs'] = [ 'must be a non-empty list of locations' ]
    elsif jobs.size > MAX_JOBS
      problems['jobs'] = [ "must not contain more than #{MAX_JOBS} locations" ]
    else
      jobs.each_with_index { |job, index| check_location("jobs[#{index}]", job) }
    end
    problems.empty?
  end

  def origin_location
    Location.new(origin).to_h
  end

  def job_locations
    jobs.map { |job| Location.new(job).to_h }
  end

  private

  def check_location(key, attributes)
    return problems[key] = [ 'must be an object with lat, long and address' ] unless attributes.is_a?(Hash)

    location = Location.new(attributes)
    problems[key] = location.errors.full_messages unless location.valid?
  end
end
