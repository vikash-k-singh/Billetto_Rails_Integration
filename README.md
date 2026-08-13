# Billetto Rails Integration

A Rails application that pulls events from the Billetto API, displays them, and lets signed-in users vote on them. Votes are recorded as immutable events in Rails Event Store rather than a plain votes table.

## Requirements

- Ruby 3.3.3
- PostgreSQL

## Setup

Clone the repo and install dependencies:

```bash
bundle install
```

Copy the environment file and fill in your credentials:

```bash
cp .env.example .env
```

Open `.env` and add:

```
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
CLERK_SECRET_KEY=your_clerk_secret_key
BILLETTO_ACCESS_KEY_ID=your_billetto_access_key_id
BILLETTO_ACCESS_KEY_SECRET=your_billetto_access_key_secret
```

Create and migrate the database:

```bash
rails db:create
rails db:migrate
```

Pull events from Billetto:

```bash
rails billetto:ingest
```

Start the server:

```bash
rails server
```

Visit `http://localhost:3000` to see the events listing.

## Running Tests

```bash
bundle exec rspec
```

## Background Jobs

Vote count updates are processed synchronously in the current setup, when a vote is cast, the read model updates in the same request. This keeps the local development experience simple without needing Redis or a separate worker process.

In a production environment this would move to a background job processor. Rails 8 ships with Solid Queue which is a good fit here since it runs on the existing database with no extra infrastructure. The handler architecture already supports this, switching would just mean changing the subscription lambda in `ApplicationSubscriptions` from a synchronous call to an async job dispatch.

---

## Design Notes

### Why Rails Event Store for voting?

The simplest approach would be a `votes` table with a counter cache. I went with Rails Event Store instead because the assignment asked for it, and it fits naturally here. Each vote is recorded as an immutable `EventUpvoted` or `EventDownvoted` fact with the user's ID and the event ID. This means you have a full audit trail, you can always see who voted on what and when, and you can rebuild the vote counts at any time just by replaying the events.

The displayed counts come from a `VoteCount` read model that gets updated by a handler whenever a vote event is published. This keeps the event listing page fast, it's a simple database read rather than aggregating across the event store on every request.

### Domain structure

I followed the module patterns from the codebase guide. Commands (`UpvoteEvent`, `DownvoteEvent`) go through a command bus that wraps execution in a database transaction and handles instrumentation. The `Voting::Service` handler does the actual work: checks whether the user has already voted, then publishes the fact to the appropriate stream.

One deliberate decision: a user can only vote once per event, and vote switching is not supported. I kept this simple on purpose. If the requirement was to allow changing a vote, you'd need to emit a retraction event and update the read model accordingly, which adds complexity that wasn't in scope here.

### Billetto API

Events are ingested via a rake task (`rails billetto:ingest`) rather than a scheduled job. The task calls the API, upserts events by their external ID, and marks anything that's no longer in the API response as unavailable. Running the task twice won't create duplicates.

The `Billetto::Adapter` acts as an anti-corruption layer, it translates the raw API response into `EventData` structs before anything touches the database. This means if Billetto changes a field name, only the adapter needs updating.

### Authentication

User authentication is handled by Clerk.com. The backend verifies the session token from the request and exposes `current_user` across controllers. The events page is public, anyone can browse events, but voting requires being signed in.

### Assumptions

- Vote counts update synchronously in the current setup, so they reflect immediately after voting. In a production deployment with async processing there would be a brief lag, which is acceptable for a voting feature.
- The app doesn't maintain a local user table. The Clerk user ID is the identifier used everywhere, stored in vote events, used for duplicate checking. User profile data (name, email) would come from the Clerk SDK if needed.
- The rake task is designed to be run manually or via cron. There's no in-app trigger for ingestion.
