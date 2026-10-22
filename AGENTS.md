# AGENTS.md

Flutter mobile app "Atom" (iOS 15+, Android 7.0+) with a local Supabase backend.
Docs are in Vietnamese; code identifiers are in English. Reply to the owner in Vietnamese, plain language.

## Read before feature work

- Requirements: `docs/SPEC.md`, `docs/FEATURES.md` (F-xxx). Terms: `GLOSSARY.md`.
- Design: see docs/design/TECH_DESIGN.md; read the relevant design doc before feature work.
  - `docs/design/DATA_MODEL.md` tables + RLS, `API_CONTRACT.md` RPC/Edge Functions, `ALGORITHMS.md` ALG-xx,
    `UI_DESIGN.md` screens S-xx, `TRACEABILITY.md` F-xxx → screen/table/API/test.
- Decisions: `docs/adr/`. Contradicting an ADR? Say so; don't silently override.
- Tickets: `.scratch/<feature>/issues/NN-*.md`. Work one ticket at a time, blockers first.

## Commands

- `make check` — pub get, format check, analyze, unit/widget tests. CI runs it on every PR.
- `make check-db` — `supabase db reset` + `supabase test db` (needs Docker running).
- `make check-all` — `check` then `check-db`.

## Layout

- `lib/` — app code; `test/` — Flutter tests.
- `supabase/config.toml`, `supabase/migrations/`, `supabase/tests/` (pgTAP).
- `.agents/skills/` — mattpocock/skills (installed via `npx skills`, see `skills-lock.json`).
- `.cursor/rules/` — always-on agent rules; `.cursor/hooks/` — agent hooks.
- `.cursor/skills/` — ponytail-review, ponytail-audit, ponytail-debt (read-only reports, from DietrichGebert/ponytail @09c434a).

## Hard rules

1. Never modify, delete, or skip tests just to make them pass.
2. Never read, create, or commit secrets or .env files. Only the Supabase anon key may appear in app config; never the service_role key.
3. Only use local Supabase. Never run `supabase link` or touch a remote project. Schema changes go through `supabase/migrations`.
4. Run `make check` before reporting a task as done, and report the actual output.
5. Stop and ask the human before: adding a new package, changing auth/payments/RLS, or editing migrations that already exist.

## Agent skills

### Issue tracker

Local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) as a `Status:` line. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md`, `docs/adr/`, `docs/design/`. See `docs/agents/domain.md`.
