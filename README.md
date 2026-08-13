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

```
Billetto API
    ↓
Billetto ACL
    ↓
Billetto::Client
    ↓
Billetto::Adapter
    ↓
Billetto::IngestService
    ↓
Event

Clerk
    ↓
VotesController
    ↓
Command::Bus
    ↓
Voting::Service
    ↓
EventUpvoted / EventDownvoted
    ↓
Rails Event Store
    ↓
ApplicationSubscriptions
    ↓
VoteCountHandler
    ↓
VoteCount
```

### Authentication

User authentication is handled by Clerk.com.

- The layout loads Clerk JS from the current application's Frontend API host.
- Sign In, Sign Up, and Sign Out controls are rendered in the nav.
- The backend reads the `__session` cookie (or a Bearer token), verifies it with `Clerk::SDK#verify_token`, and exposes `current_user`.
- There is no local users table. The Clerk `sub` claim is the user id stored on vote facts.
- The events page is public. Voting requires a verified session.

### Voting

`VotesController` stays thin: it authenticates, builds a command with `current_user.id`, and sends it to `Command::Bus`. It does not publish facts or update `VoteCount`.

A user may vote once per event. Direction switching is not supported.

Uniqueness is enforced by publishing to `Vote$<event_id>$<user_id>` with `expected_version: :none`. A second vote for the same user and event is a no-op. Concurrent duplicates raise `WrongExpectedEventVersion` and are ignored.

The same fact is linked onto:

- `Voting$<event_id>` — all votes for that event (also used to rebuild one event)
- `User$<user_id>` — all votes by that user

### Read model

`VoteCount` is a read model derived from `EventUpvoted` and `EventDownvoted`.

- `VoteCountHandler` is subscribed through `ApplicationSubscriptions`.
- It claims the voter in `applied_vote_facts` (unique on `event_id` + `user_id`) and recounts.
- Duplicate delivery does not double-count.
- `vote_counts.event_id` is unique.
- The listing reads `vote_counts` with `includes(:vote_count)`. It does not replay the event store.

The event store is the source of truth for votes. Rebuild the projection with:

```bash
bin/rails voting:rebuild_vote_counts
```

Optional: `bin/rails voting:rebuild_vote_counts[EVENT_EXTERNAL_ID]` rebuilds one event from its `Voting$` stream.

### Synchronous projection

`VoteCountHandler` runs synchronously in the same command transaction as `event_store.publish`.

The Turbo Stream vote response needs the updated count immediately. The handler is still event-driven: it only runs because a fact was published. `Handler.async` is the house-style subscription DSL; it does not enqueue a job.

Idempotent claims and recounts mean the same handler can later run asynchronously without changing vote rules.

### Billetto API

Ingestion is a rake task (`rails billetto:ingest`), not a request-path call.

```
Billetto::Client  → HTTP, timeouts, status mapping
Billetto::Adapter → pagination, mapping, malformed-row skipping
Billetto::IngestService → upsert by external_id, availability
Event             → ActiveRecord persistence
```

- The client calls `GET https://billetto.dk/api/v3/public/events`.
- Timeouts, connection failures, other Faraday transport errors, 401, 429, 5xx, and invalid JSON are mapped to `Billetto::*` errors. Faraday exceptions do not leave the ACL.
- Test uses `Billetto::FakeAdapter` (`config/environments/test.rb`). Client specs stub HTTP at the Faraday boundary.
- Pagination stops when `has_more` is false, the cursor is missing/unchanged, or a page cap is reached.
- An empty successful fetch does not mark every local event unavailable.
- Re-running ingest updates existing rows by `external_id` and does not create duplicates.

### Architectural decisions

The Developer's Guide contains patterns for domains such as long-lived RFC workflows. This application does not require those patterns for the Billetto event catalog and voting workflow.

- `Event` is a persistence model keyed by `external_id`, not a tid aggregate, so it is not registered in `ObjectRepository` and does not use `EventStoreInjector` or AggregateRoot.
- Voting is a single command that publishes one fact. There is no long-lived process, so there is no process manager.
- There is no cross-module collaboration, so there is no `app/integrators` handler.
- There are no incoming webhooks.

### Assumptions and trade-offs

- One vote per user per event. Changing a vote would need a retraction fact and a compensating projection update.
- Vote counts are updated in the same request as the vote.
- Ingest is manual or cron. There is no in-app trigger.
- Unavailable events are hidden from the listing.
- Listing is paginated (25 per page) and ordered by `starts_at`.
