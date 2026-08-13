require 'rails_helper'

RSpec.describe ClerkFrontend do
  around do |example|
    original_api = ENV['CLERK_FRONTEND_API']
    original_pk  = ENV['CLERK_PUBLISHABLE_KEY']
    example.run
    ENV['CLERK_FRONTEND_API'] = original_api
    ENV['CLERK_PUBLISHABLE_KEY'] = original_pk
  end

  describe '.frontend_host' do
    it 'uses CLERK_FRONTEND_API when present' do
      ENV['CLERK_FRONTEND_API'] = 'https://my-app.clerk.accounts.dev/'
      expect(described_class.frontend_host).to eq('my-app.clerk.accounts.dev')
    end

    it 'derives the host from a publishable key' do
      ENV['CLERK_FRONTEND_API'] = nil
      payload = Base64.strict_encode64('demo-app.clerk.accounts.dev$random')
      ENV['CLERK_PUBLISHABLE_KEY'] = "pk_test_#{payload}"
      expect(described_class.frontend_host).to eq('demo-app.clerk.accounts.dev')
    end

    it 'returns nil when the host cannot be determined' do
      ENV['CLERK_FRONTEND_API'] = nil
      ENV['CLERK_PUBLISHABLE_KEY'] = 'pk_test_not-valid'
      expect(described_class.frontend_host).to be_nil
    end
  end

  describe '.script_url' do
    it 'builds a clerk-js URL for the resolved host' do
      ENV['CLERK_FRONTEND_API'] = 'demo-app.clerk.accounts.dev'
      expect(described_class.script_url)
        .to eq('https://demo-app.clerk.accounts.dev/npm/@clerk/clerk-js@5/dist/clerk.browser.js')
    end
  end
end
