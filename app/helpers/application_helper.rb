module ApplicationHelper
  def clerk_js_url
    ClerkFrontend.script_url
  end

  def clerk_publishable_key
    ENV["CLERK_PUBLISHABLE_KEY"]
  end

  def event_votes_dom_id(event)
    "event-votes-#{event.external_id}"
  end
end
