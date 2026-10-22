---
name: next-ticket
description: >
  Run one full feature loop on the next unblocked ticket: claim, read the design,
  test-first build, make check-all, ponytail-review, PR, CI, then hand to the owner
  for merge. Use for "/next-ticket", "next ticket", "làm ticket tiếp theo", or
  "/next-ticket 05" for a specific ticket.
---

# Next ticket

One ticket per run, end to end. Reply to the owner in plain Vietnamese.
Hard stop (AGENTS.md rule 6): if the same step fails twice in a row, stop and ask the owner,
even when the second failure has a different cause. A test going red on purpose in step 3 is not a failure.

## 1. Pick and claim

1. `make doctor` must pass. Start from an up-to-date `main` with a clean tree.
2. Ticket: the one the owner named, else the first line of `make next-ticket`.
3. `git switch -c ticket/<NN>-<slug>`, set `**Status:** claimed`, commit.

## 2. Understand, then ask once

1. Read the ticket, every design doc and ADR it cites, and `GLOSSARY.md`.
   Find the code it touches with `graphify query "<question>"` when `graphify-out/` exists.
2. List what needs the owner (AGENTS.md rule 5): a new package, an auth/payments/RLS change,
   an edit to an existing migration, or a design gap or contradiction.
   Ask all of them in one AskQuestion before writing code. Nothing to ask: say so and go on.

## 3. Build test-first

Follow the `tdd` skill. The ticket's acceptance criteria are the seams the owner already agreed;
ask only before testing a seam outside them.

For each criterion: write one failing test, run it, and keep the red output (one line per
criterion goes in the ticket comment). Then the least code that turns it green.
DB rules get pgTAP tests in `supabase/tests/`; schema changes are new files in `supabase/migrations/`.

## 4. Verify

1. `make check-all` and `make docs-check` green. Quote the real result lines.
2. Run the `ponytail-review` skill on the branch. Fix every "Must fix". List the rest in the ticket.
3. If the change has a screen, and a booted simulator is available, run the flow once and take a screenshot.
   Otherwise write "UI not run on a device" in the ticket.

## 5. Hand over

1. Tick the criteria that are met, set `**Status:** ready-for-human`, add a dated `## Comments`
   entry: what was built, red→green per criterion, review result, what was not checked.
2. Commit, push, `gh pr create` (body: what, verified, not yet), then `gh pr checks --watch`.
   CI red: fix and push once. Red again: stop and ask.
3. Report to the owner: outcome first, then what to check (1–3 items). Ask whether to merge.

Never merge without the owner's yes. On yes: set `**Status:** resolved`, push, wait for green CI,
`gh pr merge --merge --delete-branch`, then `git switch main && git pull`.
