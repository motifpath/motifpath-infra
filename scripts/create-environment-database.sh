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
# The connection goes through a Session Manager port forward via the VM (see
# lib/postgres-forward.sh). The application user's password is the one
# Terraform put into the environment's DATABASE_URL.
set -euo pipefail

env=${1:-}
[[ $env == staging || $env == production ]] || { echo "usage: $0 <staging|production>" >&2; exit 2; }

source "$(dirname "$0")/lib/postgres-forward.sh"

db_name=$(terraform -chdir="environments/$env" output -raw database_name)
db_password=$(terraform -chdir="environments/$env" output -raw database_password)

start_postgres_forward

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
