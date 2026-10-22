#!/bin/bash
# Print ready-for-agent tickets whose blockers are all resolved, lowest number first.
# Exit 1 when none is ready.
issues_dir=.scratch/atom-mvp/issues
found=0

for t in "$issues_dir"/[0-9][0-9]-*.md; do
  grep -qE '^\*\*Status:\*\* ready-for-agent$' "$t" || continue
  open=""
  for n in $(sed -n 's/^\*\*Blocked by:\*\* //p' "$t" | grep -oE '[0-9]{2}'); do
    grep -qE '^\*\*Status:\*\* resolved$' "$issues_dir/$n-"*.md 2>/dev/null || open="$open $n"
  done
  if [[ -z "$open" ]]; then
    echo "$t"
    found=1
  fi
done

[[ $found -eq 1 ]] || { echo "next-ticket: nothing is ready-for-agent with all blockers resolved" >&2; exit 1; }
