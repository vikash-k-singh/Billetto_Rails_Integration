require 'rails_helper'

RSpec.describe Handler do
  let(:event_a) { Class.new }
  let(:event_b) { Class.new }

  let(:handler_class) do
    evt = event_a
    Class.new do
      include Handler.async(queue: 'low')
      subscribes_to evt
    end
  end

  describe '.subscriptions' do
    it 'maps the subscribed event class to the handler class' do
      expect(handler_class.subscriptions[event_a]).to include(handler_class)
    end

    it 'does not include unsubscribed event classes' do
      expect(handler_class.subscriptions[event_b]).to be_nil
    end

    it 'exposes the async queue name' do
      expect(handler_class.async_queue).to eq('low')
    end
  end

  describe '.subscribes_to with multiple events' do
    it 'registers all of them' do
      ea, eb = Class.new, Class.new
      klass = Class.new do
        include Handler.async(queue: 'default')
        subscribes_to ea, eb
      end
      expect(klass.subscriptions.keys).to contain_exactly(ea, eb)
    end
  end
end
