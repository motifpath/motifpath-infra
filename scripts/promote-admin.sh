#!/usr/bin/env bash
# promote-admin.sh — makes one registered user of an environment an admin.
#
#   scripts/promote-admin.sh <staging|production>                  # list the newest users
#   scripts/promote-admin.sh <staging|production> <clerk_user_id>  # promote that user
#
# Run from the repository root, with AWS credentials for the account, the
# Session Manager plugin and psql installed. The user must have signed in to
# the app once, so their row exists. Asks before changing anything.
#
# The app never grants admin itself: signing up only ever creates students
# and teachers, so the first admin of an environment (and any later one) is
# set here, directly in the database. The role is read from the database on
# every request, so the change takes effect on the user's next page load.
set -euo pipefail

env=${1:-}
clerk_user_id=${2:-}
[[ $env == staging || $env == production ]] ||
	{ echo "usage: $0 <staging|production> [clerk_user_id]" >&2; exit 2; }

source "$(dirname "$0")/lib/postgres-forward.sh"

db_name=$(terraform -chdir="environments/$env" output -raw database_name)

start_postgres_forward

# The master user was granted the application role when the database was
# created, so it may read and change the application's tables.
run_psql() {
	PGPASSWORD=$admin_password psql -v ON_ERROR_STOP=1 -q -X \
		-h 127.0.0.1 -p "$local_port" -U "$admin_user" -d "$db_name" "$@"
}

if [[ -z $clerk_user_id ]]; then
	echo "newest users in $db_name (promote one with: $0 $env <clerk_user_id>):"
	run_psql -c 'SELECT clerk_user_id, display_name, role, registered_at
		FROM users ORDER BY registered_at DESC LIMIT 10'
	exit 0
fi

current=$(run_psql -tA -F ' | ' -v id="$clerk_user_id" <<'SQL'
SELECT display_name, role FROM users WHERE clerk_user_id = :'id'
SQL
)
[[ -n $current ]] ||
	{ echo "no user with clerk_user_id $clerk_user_id in $db_name — have they signed in yet?" >&2; exit 1; }
if [[ $current == *' | admin' ]]; then
	echo "$clerk_user_id ($current) is already an admin in $db_name"
	exit 0
fi

read -r -p "make $clerk_user_id ($current) an admin in $db_name? [y/N] " answer
[[ $answer == y || $answer == Y ]] || { echo "nothing changed"; exit 1; }

run_psql -v id="$clerk_user_id" <<'SQL'
UPDATE users SET role = 'admin' WHERE clerk_user_id = :'id'
RETURNING clerk_user_id, display_name, role;
SQL
