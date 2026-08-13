require 'rails_helper'

RSpec.describe Command::Bus do
  subject(:bus) { described_class.new }

  let(:test_command) { Struct.new(:value).new('test') }
  let(:handler)      { ->(cmd) { "handled: #{cmd.value}" } }

  before { bus.register(test_command.class, handler) }

  describe '#call' do
    it 'calls the registered handler and returns its result' do
      expect(bus.call(test_command)).to eq('handled: test')
    end

    it 'wraps execution in an ActiveRecord transaction' do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      bus.call(test_command)
    end

    it 'instruments the command execution via ActiveSupport::Notifications' do
      names = []
      ActiveSupport::Notifications.subscribed(
        ->(name, *) { names << name }, /command/
      ) { bus.call(test_command) }
      expect(names).not_to be_empty
    end
  end

  describe '#call without a registered handler' do
    it 'raises ArgumentError' do
      bus2 = described_class.new
      expect { bus2.call(test_command) }.to raise_error(ArgumentError, /No handler/)
    end
  end

  describe 'command validation' do
    let(:validatable) do
      stub_const('TestValidatableCommand', Class.new do
        include ActiveModel::Validations
        attr_accessor :name
        validates :name, presence: true

        def initialize(name: nil)
          @name = name
        end
      end)
    end

    it 'raises Command::Invalid for an invalid command' do
      bus.register(validatable, ->(*) { :ok })
      expect { bus.call(validatable.new) }.to raise_error(Command::Invalid)
    end

    it 'calls the handler when the command is valid' do
      bus.register(validatable, ->(*) { :ok })
      expect(bus.call(validatable.new(name: 'ok'))).to eq(:ok)
    end
  end
end
