#!/usr/bin/env bash
# create-environment-database.sh — creates (or re-syncs the password of) one
# environment's database and user on the shared Postgres instance.
#
#   scripts/create-environment-database.sh <staging|production>
#
# Run from the repository root, after `terraform apply` in environments/shared
# and environments/<environment>, with AWS credentials for the account, the
# Session Manager plugin and psql installed. Safe to run again.
#
# The database is not reachable from the internet, so the connection goes
# through a Session Manager port forward via the VM. The application user's
# password is the one Terraform put into the environment's DATABASE_URL.
set -euo pipefail

env=${1:-}
[[ $env == staging || $env == production ]] || { echo "usage: $0 <staging|production>" >&2; exit 2; }

region=us-east-2
local_port=15432
param() {
	aws ssm get-parameter --region "$region" --with-decryption \
		--name "/motifpath/shared/postgres/$1" --query Parameter.Value --output text
}

address=$(param ADDRESS)
admin_user=$(param USERNAME)
admin_password=$(param PASSWORD)
instance_id=$(terraform -chdir=environments/shared output -raw vm_instance_id)
db_name=$(terraform -chdir="environments/$env" output -raw database_name)
db_password=$(terraform -chdir="environments/$env" output -raw database_password)

command -v session-manager-plugin >/dev/null ||
	{ echo "the Session Manager plugin is not installed" >&2; exit 1; }

echo "forwarding localhost:$local_port to $address:5432 through $instance_id"
forward_log=$(mktemp)
aws ssm start-session --region "$region" --target "$instance_id" \
	--document-name AWS-StartPortForwardingSessionToRemoteHost \
	--parameters "host=$address,portNumber=5432,localPortNumber=$local_port" >"$forward_log" 2>&1 &
forward=$!
trap 'kill "$forward" 2>/dev/null || true; rm -f "$forward_log"' EXIT

forward_failed() {
	echo "$1; port forward output:" >&2
	cat "$forward_log" >&2
	exit 1
}
ready=
for _ in $(seq 30); do
	kill -0 "$forward" 2>/dev/null || forward_failed "the port forward exited"
	if PGPASSWORD=$admin_password pg_isready -q -h 127.0.0.1 -p "$local_port"; then
		ready=1
		break
	fi
	sleep 1
done
[[ -n $ready ]] || forward_failed "Postgres did not answer on localhost:$local_port within 30s"

# The admin user is granted the application role so it may create a
# database owned by it. The application user owns its database, which the
# service's startup migrations need, and nobody else may connect to it.
PGPASSWORD=$admin_password psql -v ON_ERROR_STOP=1 -q \
	-h 127.0.0.1 -p "$local_port" -U "$admin_user" -d postgres \
	-v db="$db_name" -v pw="$db_password" -v admin="$admin_user" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'db', :'pw')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'db') \gexec
SELECT format('ALTER ROLE %I PASSWORD %L', :'db', :'pw') \gexec
SELECT format('GRANT %I TO %I', :'db', :'admin') \gexec
SELECT format('CREATE DATABASE %I OWNER %I', :'db', :'db')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db') \gexec
SELECT format('REVOKE ALL ON DATABASE %I FROM PUBLIC', :'db') \gexec
SQL

echo "$db_name is ready"
