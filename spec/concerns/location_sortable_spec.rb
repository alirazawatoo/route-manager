# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocationSortable do
  subject(:sorter) { Class.new { include LocationSortable }.new }

  let(:gogetter) { { id: 0, lat: 3.1224467, long: 101.5884673, address: 'Ara Damansara' } }
  let(:sunway) { { id: 1, lat: 3.0716104, long: 101.6055764, address: 'Bandar Sunway' } }
  let(:pju) { { id: 2, lat: 3.1115114, long: 101.5861952, address: 'Jalan PJU 1a/4a' } }
  let(:mont_kiara) { { id: 3, lat: 3.1660785, long: 101.6531737, address: 'Mont Kiara' } }

  it 'orders stops nearest first and keeps their ids' do
    sorted = sorter.sort_route_locations(gogetter, [ mont_kiara, sunway, pju ])

    expect(sorted.pluck(:id)).to eq [ 2, 1, 3 ]
  end

  it 'reports straight-line distance in kilometres' do
    sorted = sorter.sort_route_locations(gogetter, [ sunway, pju, mont_kiara ])

    expect(sorted.pluck(:distance_km)).to eq [ 1.24, 5.96, 8.67 ]
  end

  it 'leaves the caller’s job hashes untouched' do
    jobs = [ sunway, pju ].map(&:dup).freeze
    snapshot = jobs.map(&:dup)

    sorter.sort_route_locations(gogetter, jobs)

    expect(jobs).to eq snapshot
  end

  it 'breaks distance ties by id so the order is deterministic' do
    twin_b = pju.merge(id: 'b')
    twin_a = pju.merge(id: 'a')

    expect(sorter.sort_route_locations(gogetter, [ twin_b, twin_a ]).pluck(:id)).to eq %w[a b]
  end
end
