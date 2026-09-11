# Thomas IT Helpdesk

A support-ticket helpdesk for Thomas Information Technology, with client
self-service, team/multi-seat Stripe billing, SLA escalation, and AI
ticket categorization. Deployed at
`https://thomasinformationtechnology.com`.

## Roles

- **client** — self-service sign-up (`/signup`). Sees only their own
  organization's tickets, manages billing if they're the organization
  owner, can rate a resolved ticket (CSAT).
- **employee** — internal Thomas IT staff filing their own tickets.
- **agent** / **admin** — see and work every ticket, plus `/agents`,
  `/reports`, and the `/api/ai/status` endpoint. Only `admin` can delete a
  ticket. Provisioning is still CLI/rake-based — there's no admin UI for
  creating staff accounts yet.

## Billing (Phase 12: team billing)

Subscription state lives on `Organization`, not `User` — a client's first
checkout creates their own organization; the owner can invite teammates
(`/team`), who share the same plan and see the same tickets, but only the
owner can change plans or open the Stripe billing portal. See
`Plan::ALL` in `app/models/plan.rb` for the three tiers.

## AI ticket categorization (Phase 14)

`TicketCategorizer` calls the Claude API to suggest a category for any
ticket a client leaves uncategorized, run async via `TicketCategorizationJob`
so it can never slow down or fail ticket creation. Requires
`ANTHROPIC_API_KEY`; with no key set, it's a no-op. `/api/ai/status`
(staff-only) reports whether it's configured and how many tickets it has
actually categorized.

## Real-time updates (Phase 10)

Ticket escalations and successful AI categorizations broadcast over
Action Cable (`TicketUpdatesChannel`) and show up as a dismissible banner
for staff. Production uses Solid Cable (not Redis — nothing else in this
app needs a Redis service), running in the same database as everything
else.

## Ticket attachments

Clients and staff can attach files (image/PNG/JPEG/GIF/WebP, PDF, or
plain text — deliberately no SVG or HTML, both can carry an embedded
script) when creating or editing a ticket, up to 5 files / 10MB each (see
`Ticket::ALLOWED_ATTACHMENT_TYPES`). Downloads go through
`TicketAttachmentsController`, which checks `TicketPolicy` before
redirecting to the file — Active Storage's own blob URLs don't check our
authorization on their own. **Production caveat**: storage is local disk
(`config.active_storage.service = :local`), same as dev/test, which makes
uploads work immediately but means files are lost on every Render
redeploy unless a persistent disk or an S3-compatible service is
configured — neither of which this codebase can set up on its own.

## Running locally

```
bin/setup
bin/rails db:seed  # employee@thomasit.com / agent@thomasit.com / admin@thomasit.com, password "changeme123"
bin/rails server
```

Copy `.env.example` to `.env` for Stripe test keys. Run `bin/rails
stripe:setup_plans` once to create the three Stripe Prices and print the
`STRIPE_PRICE_*` env vars to set.

## Tests

```
bin/rails test        # unit/integration
bin/rails test:system # Capybara/system tests
bin/ci                 # full CI suite (also runs in GitHub Actions)
```
