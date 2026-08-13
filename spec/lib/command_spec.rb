require 'rails_helper'

RSpec.describe Command::Handler do
  let(:test_command) do
    Struct.new(:name) do
      include ActiveModel::Validations
      validates :name, presence: true
    end
  end

  let(:handler_class) do
    cmd = test_command
    Class.new do
      include Command::Handler
      handles cmd, :process

      private

      def process(command)
        "processed: #{command.name}"
      end
    end
  end

  subject(:handler) { handler_class.new }

  describe '#call' do
    it 'dispatches to the registered method' do
      expect(handler.call(test_command.new('hello'))).to eq('processed: hello')
    end

    it 'raises ArgumentError for an unregistered command' do
      expect { handler.call(Struct.new(:x).new('y')) }
        .to raise_error(ArgumentError, /No handler/)
    end
  end

  describe '.handles' do
    it 'records the command class in command_map' do
      expect(handler_class.command_map.keys).to include(test_command)
    end
  end
end