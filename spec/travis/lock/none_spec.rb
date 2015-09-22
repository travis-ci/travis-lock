describe Travis::Lock::None do
  let(:lock) { described_class.new }

  it 'yields' do
    lock.exclusive { @called = true }
    expect(@called).to eq(true)
  end
end
