# The Getaway Crew

**Plan together. Go together. Make memories.**

This repository now includes a responsive HTML/CSS/JavaScript site modeled on the existing Floot app's coastal-travel design, trip types, section names, and planning interactions.

## Open the website

Publish this repository using GitHub Pages or connect it to the existing Cloudflare `gataway` site. The entry point is `index.html`. All assets are relative to the site's path. Preview locally using a static web server.

## Functionality in the GitHub edition

- Create, edit, duplicate and filter customizable trips (multiple types, flexible sections, status, dates, timezone and budget).
- Crew household planning notes and RSVPs; dates, ideas and votes, itineraries, expenses and reported/confirmed payments, bookings, rooms/rides, checklists, group feed, memory/photo links, and preferences.
- Mobile-friendly layout inspired by the Floot design; theme modes System/Light/Dark/AMOLED, adjustable Liquid Glass and installable manifest.
- Print trip summary / save to PDF, export a JSON backup and import it later.
- Automatic save in *this browser only* via `localStorage`.

## Security and synchronization limitations

**This standalone GitHub build is NOT connected to Floot login, Floot database, Supabase Auth, or a secure group-trip API.** It does not synchronize trips across browsers, devices or users; invitation codes and per-user access controls are not supported. Member roles and visibility labels are planning notes only. Don't put secrets, passwords, or private trip/financial information into the static edition. The Floot version remains the source of truth for private collaborative trips and authenticated access.

To establish real shared data, both sites need to use a purpose-built, secured API with server-side authorization (for example, a dedicated Supabase schema with appropriate RLS policies), plus an explicit account-linking plan. Never expose service-role keys in GitHub or browser code, and never assume existing Floot sessions can be reused directly on another domain.

## Hosting

For **GitHub Pages**: Repository Settings → Pages → Deploy from a branch → `main` → `/ (root)`. If available, it will be hosted at `https://jhamal96.github.io/gataway/`. This URL is a proposed convention, not verified active.

For **Cloudflare**: point the existing `gataway` site at this repository's static assets, preserving any existing Worker routing until reviewed. No Cloudflare deployment has been made by this change.

The full Floot app has its own hosting lifecycle and private database. Updates to Floot do not automatically propagate to the static GitHub edition.
