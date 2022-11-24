# frozen_string_literal: true

# A point on a route: the gogetter's starting point or a job stop.
# Coordinates drive the routing; the address is what the driver reads.
class Location
  include ActiveModel::Model

  MAX_ADDRESS_LENGTH = 500

  attr_accessor :id, :lat, :long, :address

  validates :lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :long, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :address_is_present_text

  def to_h
    { id: id, lat: Float(lat), long: Float(long), address: address.strip }.compact
  end

  private

  def address_is_present_text
    if !address.is_a?(String)
      errors.add(:address, address.nil? ? :blank : 'must be a string')
    elsif address.strip.empty?
      errors.add(:address, :blank)
    elsif address.length > MAX_ADDRESS_LENGTH
      errors.add(:address, :too_long, count: MAX_ADDRESS_LENGTH)
    end
  end
end
