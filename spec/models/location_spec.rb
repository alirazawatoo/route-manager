# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location do
  let(:attributes) { { id: 7, lat: 3.1224467, long: 101.5884673, address: '  Ara Damansara, Petaling Jaya  ' } }

  it 'accepts coordinates in range with an address' do
    expect(described_class.new(attributes)).to be_valid
  end

  it 'accepts numeric strings and converts them to floats' do
    location = described_class.new(attributes.merge(lat: '3.12', long: '101.58'))

    expect(location).to be_valid
    expect(location.to_h).to eq(id: 7, lat: 3.12, long: 101.58, address: 'Ara Damansara, Petaling Jaya')
  end

  it 'omits a missing id from the hash' do
    expect(described_class.new(attributes.except(:id)).to_h).not_to have_key(:id)
  end

  {
    'a missing address' => { address: nil },
    'a blank address' => { address: '   ' },
    'a non-string address' => { address: 12_345 },
    'an over-long address' => { address: 'x' * 501 }
  }.each do |description, change|
    it "rejects #{description}" do
      location = described_class.new(attributes.merge(change))

      expect(location).not_to be_valid
      expect(location.errors[:address]).not_to be_empty
    end
  end

  {
    'a missing latitude' => { lat: nil },
    'a non-numeric latitude' => { lat: 'north' },
    'a latitude above 90' => { lat: 90.1 },
    'a longitude below -180' => { long: -180.5 },
    'a longitude given as a list' => { long: [ 1, 2 ] }
  }.each do |description, change|
    it "rejects #{description}" do
      expect(described_class.new(attributes.merge(change))).not_to be_valid
    end
  end
end
