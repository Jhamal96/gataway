# Getaway Crew 2.0 — Security test runner

Supabase development project: `mgehamvbkugwctdcmqcp`
Edge Function: `getaway-v2-security-tests` (JWT verification enabled).

## Current scope
The deployed endpoint is a protected, read-only scaffold. It reports the safety configuration and explicitly skips organizer authorization scenarios. It does **not** prove that owner grants, revocations, expirations, or audit logging work.

The development dashboard at `development/security-testing.html` currently runs browser-local checks. It is **not yet connected** to the Edge Function: the app needs a trusted authenticated development session and an explicitly approved development origin. Do not put a service-role key or secret in browser code.

## Required next steps
1. Configure a dedicated development authentication flow and authorize only the development dashboard origin.
2. Implement a server-side isolated fixture lifecycle and real permission assertions, with deterministic cleanup.
3. Gate test-account provisioning behind an explicit opt-in and protect it against production use.
4. Run unauthorized grant, self-promotion, expiry, revocation, renewal, and audit assertions.
5. Wire the dashboard to display actual server results and mark all unavailable tests as skipped.
6. Review before any production rollout.

No owner account has been bootstrapped or linked. Live Floot and production remain untouched.

## Reserved developer account (not provisioned)
- Email: `alain_dabady@yahoo.com`
- Status: reserved for later development signup; no password, credential, or auth user created.
- Activation: owner must choose a password or complete a secure passwordless verification flow later.
- Do not automatically grant platform primary-owner access based on matching email. Bind authorization to a verified Supabase Auth user ID after explicit approval.
- Do not send invitations or password reset messages without a separate request.
