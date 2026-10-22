.PHONY: check check-db check-all doctor docs-check next-ticket

doctor:
	@bash scripts/doctor.sh

docs-check:
	@bash scripts/docs_check.sh

next-ticket:
	@bash scripts/next_ticket.sh

check:
	flutter pub get
	dart format --set-exit-if-changed .
	flutter analyze
	flutter test

check-db:
	@docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker Desktop first."; exit 1; }
	supabase db reset
	supabase test db

check-all: check check-db
