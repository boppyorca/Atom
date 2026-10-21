.PHONY: check check-db check-all

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
