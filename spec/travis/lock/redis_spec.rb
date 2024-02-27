# frozen_string_literal: true

describe Travis::Lock::Redis do
  let(:config) { { url: 'redis://localhost' } }
  let(:client) { stub('redlock', lock: nil) }
  let(:lock)   { described_class.new(name, config) }
  let(:name)   { 'name' }

  after { described_class.instance_variable_set(:@clients, nil) }

  it 'yields' do
    lock.exclusive { @called = true }
    expect(@called).to eq(true)
  end

  it 'delegates to a Redlock instance' do
    Redlock::Client.stubs(:new).returns(client)
    client.expects(:lock).with(name, 300_000)
    lock.exclusive {}
  end
end
