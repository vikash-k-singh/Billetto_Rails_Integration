require 'rails_helper'

RSpec.describe 'Authentication and voting', type: :system do
  let!(:event) { create(:event, title: 'Jazz Night') }

  it 'shows sign in and sign up when logged out' do
    visit root_path
    expect(page).to have_button('Sign In')
    expect(page).to have_button('Sign Up')
    expect(page).to have_content('Sign in to vote on events.')
    expect(page).not_to have_css('button[aria-label="Upvote"]')
  end

  it "shows sign out and vote controls when logged in" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ "sub" => "usr_system" })
    page.driver.browser.set_cookie("__session=test-session-token; path=/")

    visit root_path
    expect(page).to have_button("Sign Out")
    expect(page).to have_css('button[aria-label="Upvote"]')
    expect(page).to have_css('button[aria-label="Downvote"]')
  end

  it "signs the user out from the header" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ "sub" => "usr_system" })
    page.driver.browser.set_cookie("__session=test-session-token; path=/")

    visit root_path
    click_button "Sign Out"
    expect(page).to have_button("Sign In")
    expect(page).to have_button("Sign Up")
    expect(page).not_to have_button("Sign Out")
  end

  it "drops Clerk handshake params from the URL without a manual refresh" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ "sub" => "usr_system" })

    visit "/?__clerk_handshake=handshake-token"
    expect(page).to have_current_path(root_path)
  end

  it "lets a signed-in user upvote an event" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ "sub" => "usr_system" })
    page.driver.browser.set_cookie("__session=test-session-token; path=/")

    visit root_path
    find('button[aria-label="Upvote"]').click
    expect(page).to have_current_path(events_path)
    expect(page).to have_content("👍 1")
  end
end
