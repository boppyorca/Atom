#!/bin/bash
# Check this machine has the tools the harness expects. Exit 1 if a required one is missing.
fail=0

need() { # name, version-command, expected substring ("" = any)
  if ! command -v "$1" >/dev/null; then
    echo "MISSING  $1"; fail=1; return
  fi
  local v; v=$(eval "$2" 2>/dev/null | head -1)
  if [[ -n "$3" && "$v" != *"$3"* ]]; then
    echo "VERSION  $1: have '$v', want $3"; fail=1
  else
    echo "ok       $1 $v"
  fi
}

optional() { # name, hint
  if command -v "$1" >/dev/null; then echo "ok       $1"; else echo "optional $1 not found: $2"; fi
}

need flutter "flutter --version" "3.47.7"
need supabase "supabase --version" "2.121.0"
need docker "docker --version" ""
need jq "jq --version" ""
need git "git --version" ""

if command -v docker >/dev/null && ! docker info >/dev/null 2>&1; then
  echo "DOWN     docker is installed but not running (start Docker Desktop)"; fail=1
fi

optional gh "needed to open PRs (brew install gh, then gh auth login)"
optional graphify "code graph for agents (see AGENTS.md)"

exit $fail
