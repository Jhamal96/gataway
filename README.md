# The Getaway Crew

Collaborative group-trip planner (working name, project slug `gataway`).

## Product direction
- Support mixed trip types: weekend getaways, road trips, cruises, flights, international travel, day trips, celebrations and group events.
- Each trip can change its type, location, dates, guest list, budget and itinerary without being recreated.
- Invitation-based crews, member roles, trip voting/polls, RSVPs, shared itinerary, lodging, transportation, expenses, payment milestones, packing lists, activities and group announcements.
- Responsive mobile-first interface, accessible light/dark/AMOLED themes and optional adjustable translucent glass effect.

## Infrastructure
- GitHub: `Jhamal96/gataway` (source repository).
- Cloudflare: existing Worker `gataway`. Confirm configuration before updating or replacing it.
- Supabase: **dedicated new project proposed** called `getaway`, pending organization selection and cost authorization if applicable.
- Keep Supabase Auth for Getaway separate from all existing apps. Never connect the Getaway frontend to the shared legacy auth database. Do not migrate or delete existing users.
- Use Supabase Auth with email/password and optionally OAuth, Supabase Postgres for data, RLS for crew membership and trip access, and Storage for trip images/attachments.
- Store only publishable Supabase URL/key in client config; never commit service keys or secrets.

## Data model draft
- profiles (user_id)
- trips (id, owner_id, title, category, destination, date range, status)
- trip_members (trip_id, user_id, membership role, RSVP state)
- trip_invitations (trip_id, invite token hash, expiration, status)
- votes and vote_options
- itinerary_items
- accommodations, transportation
- expenses, expense_splits, payments
- packing_items, tasks
- activity_log and notifications

Every trip-specific table must enforce membership-sensitive Row Level Security. Owner/admin privileges cannot be determined from editable user metadata.

## Next implementation checkpoints
1. Confirm dedicated Supabase organization and project pricing; create `getaway` project.
2. Define RLS and membership roles, and verify isolated sign-up/login flows.
3. Scaffold responsive frontend and securely bind Supabase project.
4. Test group invitation flows and authorization using two separate accounts.
5. Attach GitHub to Cloudflare deployment and test privately before public release.
