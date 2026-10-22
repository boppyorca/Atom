#!/bin/bash
# beforeShellExecution: deny commands that break AGENTS.md hard rules, ask on risky ones.
cmd=$(jq -r '.command // empty')

reply() { jq -nc --arg p "$1" --arg m "$2" '{permission: $p, user_message: $m, agent_message: $m}'; }

deny_patterns=(
  'supabase[[:space:]]+(link|db[[:space:]]+push|secrets|projects|functions[[:space:]]+deploy)|--linked|--project-ref'
  'git[[:space:]]+push[[:space:]].*(--force|-f([[:space:]]|$))'
  'git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*f)'
  'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+(/|~|\$HOME|\.|\*)([[:space:]]|/?$)'
  '(^|[[:space:];|&])sudo[[:space:]]'
  '(curl|wget)[^|]*\|[[:space:]]*(ba|z)?sh'
  '(cat|less|more|head|tail|grep|source|cp|mv)[[:space:]](.*[[:space:]/])?\.env([^.a-zA-Z]|\.[a-df-z]|$)'
)
ask_patterns=(
  '(flutter|dart)[[:space:]]+pub[[:space:]]+(add|remove|upgrade)'
  'rm[[:space:]]+-[a-zA-Z]*r'
  'git[[:space:]]+(push|branch[[:space:]]+-D)'
)

for p in "${deny_patterns[@]}"; do
  if [[ "$cmd" =~ $p ]]; then
    reply deny "Blocked by .cursor/hooks/block-dangerous.sh (AGENTS.md hard rules). Ask the owner instead."
    exit 0
  fi
done
for p in "${ask_patterns[@]}"; do
  if [[ "$cmd" =~ $p ]]; then
    reply ask "Risky command (package change, recursive delete or push). Owner must approve."
    exit 0
  fi
done
echo '{"permission":"allow"}'
