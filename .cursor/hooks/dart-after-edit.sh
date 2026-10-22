#!/bin/bash
# postToolUse (Write): format the edited .dart file, feed analyzer issues back to the agent,
# and refresh the local graphify graph in the background.
file=$(jq -r '.tool_input.file_path // .tool_input.path // .tool_input.target_file // .file_path // empty')

if [[ ("$file" == *.dart || "$file" == *.sql) && -d graphify-out ]] && command -v graphify >/dev/null; then
  (graphify update . >/dev/null 2>&1 &)
fi

if [[ "$file" != *.dart || ! -f "$file" ]]; then
  echo '{}'
  exit 0
fi

dart format "$file" >/dev/null 2>&1
issues=$(dart analyze "$file" 2>&1)

if [[ $? -eq 0 ]]; then
  echo '{}'
else
  jq -nc --arg c "dart analyze $file:
$issues" '{additional_context: $c}'
fi
