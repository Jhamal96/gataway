# The Getaway Crew

**Plan together. Go together. Make memories.**

## Live website and shared sign-in
- Branded entry point: https://getaway.ajdapp.org/
- Shared Floot application: https://the-getaway-crew.floot.app/
- The branded Cloudflare Worker redirects to Floot to ensure the **same UI, login, real trip data, membership, invitation links, and settings** on web and app. This is intentional: the old HTML frontend used browser-only local storage and could not securely share Floot sessions.
- The GitHub `index.html` also directs visitors to Floot so GitHub Pages visitors get the same application.

## Android
- The Android WebView loads `https://the-getaway-crew.floot.app/` directly. It uses the Floot backend and **same accounts**, but Android's WebView may maintain its own login session.
- GitHub Actions builds the Android test APK from `android/` when that directory changes.
- APK download (release channel): https://github.com/Jhamal96/gataway/releases/download/android-latest/Getaway-Crew-Android.apk
- Debug/test build, not a Google Play release. If an older build was signed with a different debug key, uninstalling the older APK may be needed before installing the new one.
- Web PWA can be installed using the browser's Add to Home Screen / Install app controls.

## Features maintained in Floot
- Trip types (including cruise) with compact type-specific forms, editable/optional dates, and multiple trip links.
- Best-effort metadata previews for supported public travel domains.
- Trip departure countdown; optional personal monthly savings estimate; descriptive trip sections.
- 12-character randomized invitation codes for new trips or rotated codes, plus shareable invitation links.
- Private membership, organizers, RSVPs, shared itinerary, voting, payments tracking, task lists and memories.

## Legacy browser-only editor and preservation
- `local.html` preserves the previous HTML/CSS/JS local-only planner for exporting any previously saved browser data.
- The Cloudflare Worker also serves `https://getaway.ajdapp.org/local.html` as an archival editor under the same origin; select **Export plans** there to save a JSON backup before deleting browser data.
- Older data in browser localStorage is **not automatically migrated** to Floot. Never assume that locally created trips are visible to other accounts.
- `app.js`, `styles.css` and `manifest.webmanifest` remain solely to support this local backup editor.

## Download Hub
- The Download Hub's Supabase `public.apps` catalog lists the branded website and verified Android APK.
- https://download.ajdapp.org/

## Security
Authentication and trip membership are enforced by Floot's backend. Do not store passwords or Floot session tokens in the GitHub static files. The worker is a navigation redirect, not an auth proxy; it does not expose any authentication secrets. Existing Supabase authentication accounts were not modified.
