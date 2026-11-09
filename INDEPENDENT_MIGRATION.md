# Independent Getaway Crew migration

**Status:** Preview available at https://getaway.ajdapp.org/preview . Production at https://getaway.ajdapp.org/ remains on Floot **until user ownership, file migration, and access testing are complete**. Do not cut over early.

## What has been done
- Created the GitHub development branch `development/independent-cloudflare-supabase`, preserving `main`.
- Created independent HTML/JS front end under `independent/`, with coastal styling, trip-type forms, links, optional dates, countdown, optional monthly savings, sections, invite codes, and Supabase Auth.
- Created Supabase tables `public.getaway_*` with RLS, trip membership checks, private records, and authenticated invite-code join.
- Imported Floot records into **private, non-exposed** `getaway.legacy_*` staging tables. Do not publish these tables or expose service credentials.
- Did **not** import password hashes, session tokens, or create/alter existing Auth accounts.
- Did **not** copy attachment file bytes. One legacy attachment remains staged as metadata with `file_migrated=false`.

## Source and destination
Source: Floot project `a7a686af-f540-4cf7-a9c5-3f3b87a501b2`, Floot-managed database.
Destination: existing Supabase `download` project `xqqqahpaunoqpitvhrlw`. Other Supabase apps remain untouched.
Data staged: 3 user profiles, 2 trips, 2 memberships, 4 records, 1 response, 1 attachment metadata record.

## Critical remaining steps before production cutover
1. **Verify legacy user ownership.** Floot IDs are integer; Supabase Auth IDs are UUID. Require authenticated ownership proof in the legacy Floot app plus verified email in the new Supabase app (or administrator-assisted verification), then set `getaway.legacy_users.supabase_user_id`. **Never auto-match only on email.**
2. **Migrate rows** from private staging to public Getaway tables, preserving UUID trip and record IDs, replacing old user IDs using verified mapping. Keep invitations rotated; old codes are not necessarily secure enough for new app.
3. **Migrate attachment bytes** from Floot storage to a private Supabase Storage bucket with per-trip access policies, preserving MIME type and filenames, and confirm checksums.
4. **Test RLS** with owner, member, nonmember, and anonymous accounts: trips, records, responses, attachments, invitations, and private savings.
5. **Test end-to-end sign-in** and password-reset flow on production domain, including email redirect allow-list, email verification, and Android APK session handling.
6. **Parity check** Floot design, settings, button placement, all sections, mobile and desktop layouts, voting, expense splitting, and permissions. The preview is a functional initial build, not yet full feature parity.
7. **Cutover** the existing Cloudflare `gataway` Worker to independent assets after verification; rebuild Android APK to point directly to the independent site. Update Download Hub only after new APK is built.
8. **Rollback** by restoring previous Worker version or GitHub `main` routing. Keep Floot running read-only until data reconciliation is signed off.

## Security
The private `getaway` schema has RLS enabled without client-access policies, intentionally. The security advisor may show informational `rls_enabled_no_policy` for these staging tables; this is a deny-by-default state.
Do not put any password hash, service role key, legacy data export, or user email list in this repository. The only embedded key is the public browser publishable key.

## Preview behavior
`https://getaway.ajdapp.org/preview` loads the new independent Supabase app. Existing Floot trips are not visible until verified migration. The preview can create **new** trips using Supabase Auth, but do not use it for production data until the migration and tests are complete.
