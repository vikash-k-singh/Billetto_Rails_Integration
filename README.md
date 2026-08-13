# Billetto Rails Integration

A Rails application that pulls events from the Billetto API, displays them, and lets signed-in users vote on them. Votes are recorded as immutable events in Rails Event Store rather than a plain votes table.

## Requirements

- Ruby 3.3.6
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
CLERK_FRONTEND_API=
BILLETTO_ACCESS_KEY_ID=your_billetto_access_key_id
BILLETTO_ACCESS_KEY_SECRET=your_billetto_access_key_secret
DATABASE_NAME=billetto_integration_development
DATABASE_USERNAME=your_pg_user
DATABASE_PASSWORD=your_pg_password
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

`CLERK_FRONTEND_API` is optional. If it is blank, the app derives the Clerk Frontend API host from `CLERK_PUBLISHABLE_KEY`. Set it explicitly if that derivation fails.

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

---

## Architecture

Voting keeps this repository's house style. It is not rewritten around AggregateRoot.

```
Controller
  → Command (UpvoteEvent / DownvoteEvent)
  → Command::Bus (correlation, validation, transaction, instrumentation)
  → Voting::Service
  → Fact (EventUpvoted / EventDownvoted)
  → Rails Event Store
  → ApplicationSubscriptions / ProjectionSubscriber
  → VoteCountHandler (synchronous)
  → VoteCount read model
```

### Authentication

User authentication is handled by Clerk.com.

- The layout loads Clerk JS from the current application's Frontend API host, not a hardcoded instance.
- Sign In, Sign Up, and Sign Out controls are rendered in the nav.
- The backend reads the `__session` cookie (or a Bearer token), verifies it with `Clerk::SDK#verify_token`, and exposes `current_user`.
- There is no local users table. The Clerk `sub` claim is the user id stored on vote facts.
- The events page is public. Voting requires a verified session.

### Voting

- `VotesController` stays thin: it authenticates, builds a command with `current_user.id`, and calls the command bus.
- Invalid commands and missing events redirect with an alert instead of raising 500s.
- A user may vote once per event. Direction switching is not supported.
- Uniqueness is enforced by publishing to `Vote$<event_id>$<user_id>` with `expected_version: :none`. Concurrent duplicates raise `WrongExpectedEventVersion` and are ignored.
- The same fact is also linked onto `Voting$<event_id>` and `User$<user_id>`.

### Rails Event Store and the read model

Each vote is an immutable `EventUpvoted` or `EventDownvoted` fact with `event_id` and `user_id`.

`ApplicationSubscriptions` registers handlers against a fresh `RailsEventStore::Client` in `to_prepare`, so development reloads do not stack subscribers.

`Handler.async` is the house-style subscription DSL (`subscribes_to`). It does not enqueue Active Job. `ProjectionSubscriber` calls `VoteCountHandler` in the same command transaction as `event_store.publish`, so the turbo-stream response can read the updated count immediately.

`VoteCountHandler` claims the voter in `applied_vote_facts` (unique on `event_id` + `user_id`) and then recounts. Retries and duplicate delivery do not double-count. `vote_counts.event_id` is unique.

If a fact is already in the `Vote$` stream but the read model was missed, `Voting::Service` re-applies that fact to `VoteCountHandler` without publishing again.

The listing reads `vote_counts` with `includes(:vote_count)`. It does not replay the event store.

### Billetto API

Ingestion is a rake task (`rails billetto:ingest`), not a request-path call.

```
Billetto::Client  → HTTP, timeouts, status mapping
Billetto::Adapter → pagination, mapping, malformed-row skipping
Billetto::IngestService → upsert by external_id, availability
Event             → ActiveRecord persistence
```

- The client calls `GET https://billetto.dk/api/v3/public/events`.
- Timeouts, connection failures, 401, 429, 5xx, and invalid JSON are mapped to `Billetto::*` errors.
- Pagination stops when `has_more` is false, the cursor is missing/unchanged, or a page cap is reached.
- An empty successful fetch does not mark every local event unavailable.
- Re-running ingest updates existing rows by `external_id` and does not create duplicates.

### Assumptions and trade-offs

- One vote per user per event. Changing a vote would need a retraction fact and a compensating projection update.
- Vote counts are updated in the same request as the vote, not by a background job.
- Ingest is manual or cron. There is no in-app trigger.
- Unavailable events are hidden from the listing.
- Listing is paginated (25 per page) and ordered by `starts_at`.
