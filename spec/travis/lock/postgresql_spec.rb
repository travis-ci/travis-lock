# frozen_string_literal: true

describe Travis::Lock::Postgresql do
  let(:lock) { described_class.new(name, config) }
  let(:name) { 'name' }
  let(:key)  { 1_579_384_326 }

  def rescueing
    yield
  rescue Travis::Lock::Timeout
  end

  shared_examples_for 'yields' do
    it 'yields' do
      lock.exclusive { @called = true }
      expect(@called).to eq(true)
    end
  end

  context 'lock' do
    let(:conn) { stub('connection', select_value: 't', execute: nil) }

    before     do
      def conn.transaction = yield
      ActiveRecord::Base.stubs(:connection).returns(conn)
    end

    shared_examples_for 'locks_with' do |method|
      it "locks_with #{method}" do
        conn.expects(:select_value).with("select #{method}(#{key});").returns('t')
        lock.exclusive {}
      end
    end

    shared_examples_for 'retries until timeout' do
      it 'retries until timeout' do
        conn.expects(:select_value).returns('f').at_least(50)
        rescueing { lock.exclusive {} }
      end
    end

    shared_examples_for 'sets a statement level timeout' do
      it 'sets a statement level timeout' do
        conn.expects(:execute).with('set statement_timeout to 100;')
        lock.exclusive {}
      end
    end

    shared_examples_for 'raises Travis::Lock::Timeout when timed out' do
      it 'raises Travis::Lock::Timeout when timed out' do
        conn.stubs(:select_value).returns('f')
        expect { lock.exclusive {} }.to raise_error(Travis::Lock::Timeout)
      end
    end

    describe 'using try_*' do
      describe 'not using transactions' do
        let(:config) { { try: true, transactional: false, timeout: 0.1 } }

        include_examples 'yields'
        include_examples 'locks_with', 'pg_try_advisory_lock'
        include_examples 'retries until timeout'
        include_examples 'raises Travis::Lock::Timeout when timed out'
      end

      describe 'using transactions' do
        let(:config) { { try: true, transactional: true, timeout: 0.1 } }

        include_examples 'yields'
        include_examples 'locks_with', 'pg_try_advisory_xact_lock'
        include_examples 'retries until timeout'
        include_examples 'raises Travis::Lock::Timeout when timed out'
      end
    end

    describe 'not using try_*' do
      describe 'not using transactions' do
        let(:config) { { try: false, transactional: false, timeout: 0.1 } }

        include_examples 'yields'
        include_examples 'locks_with', 'pg_advisory_lock'
        include_examples 'sets a statement level timeout'
        # include_examples 'raises Travis::Lock::Timeout when timed out'
      end

      describe 'using transactions' do
        let(:config) { { try: false, transactional: true, timeout: 0.1 } }

        include_examples 'yields'
        include_examples 'locks_with', 'pg_advisory_xact_lock'
        include_examples 'sets a statement level timeout'
        # include_examples 'raises Travis::Lock::Timeout when timed out'
      end
    end
  end

  # describe 'integration' do
  #   shared_examples_for 'no race condition' do
  #     runs    = ENV['RUNS']    || 1
  #     threads = ENV['THREADS'] || 10

  #     1.upto(runs) do |ix|
  #       it "does not see a race condition on #{threads} threads (run #{ix})" do
  #         counter = 0

  #         Array(1..threads).map do
  #           Thread.new do
  #             lock.exclusive do
  #               counter = counter.tap { sleep(rand(0.001)) } + 1
  #             end
  #           end
  #         end.map(&:join)

  #         expect(counter).to eq(threads)
  #       end
  #     end
  #   end

  #   describe 'using try_*' do
  #     describe 'not using transactions' do
  #       let(:config) { { try: true, transactional: false, timeout: 0.1 } }
  #       include_examples 'no race condition'
  #     end

  #     describe 'using transactions' do
  #       let(:config) { { try: true, transactional: true, timeout: 0.1 } }
  #       include_examples 'no race condition'
  #     end
  #   end

  #   describe 'not using try_*' do
  #     describe 'not using transactions' do
  #       let(:config) { { try: false, transactional: false, timeout: 0.1 } }
  #       include_examples 'no race condition'
  #     end

  #     describe 'using transactions' do
  #       let(:config) { { try: false, transactional: true, timeout: 0.1 } }
  #       include_examples 'no race condition'
  #     end
  #   end
  # end
end
