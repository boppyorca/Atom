#!/bin/bash
# Keep SPEC, ADRs and tickets consistent. Prints every problem, exits 1 if any.
issues_dir=.scratch/atom-mvp/issues
statuses='needs-triage|needs-info|ready-for-agent|ready-for-human|wontfix|claimed|resolved'
fail=0
problem() { echo "docs-check: $1"; fail=1; }

for f in $(grep -oE 'F-[0-9]{3}' docs/SPEC.md | sort -u); do
  grep -qw "$f" "$issues_dir"/*.md || problem "$f is in docs/SPEC.md but no ticket mentions it"
done

for t in "$issues_dir"/*.md; do
  name=$(basename "$t")
  grep -qE "^\*\*Status:\*\* ($statuses)\$" "$t" || problem "$name has no valid **Status:** line ($statuses)"

  blocked=$(sed -n 's/^\*\*Blocked by:\*\* //p' "$t")
  for n in $(echo "$blocked" | grep -oE '[0-9]{2}'); do
    ls "$issues_dir/$n-"*.md >/dev/null 2>&1 || problem "$name is blocked by $n, which does not exist"
  done

  for adr in $(grep -oE 'ADR-[0-9]{4}' "$t" | sort -u); do
    ls docs/adr/"${adr#ADR-}"-*.md >/dev/null 2>&1 || problem "$name cites $adr, which is not in docs/adr/"
  done
done

for doc in AGENTS.md GLOSSARY.md docs/*.md docs/design/*.md docs/adr/*.md "$issues_dir"/*.md; do
  dir=$(dirname "$doc")
  for link in $(grep -oE '\]\([^)#[:space:]]+' "$doc" | sed 's/^](//' | grep -vE '^(https?:|mailto:)'); do
    [[ -e "$dir/$link" ]] || problem "$doc links to $link, which does not exist"
  done
done

[[ $fail -eq 0 ]] && echo "docs-check: ok"
exit $fail
