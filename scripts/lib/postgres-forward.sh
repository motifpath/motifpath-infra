# postgres-forward.sh — sourced by the operator scripts that talk to the
# shared Postgres instance. Not meant to be run on its own.
#
# The database is not reachable from the internet, so the connection goes
# through a Session Manager port forward via the VM. After
# start_postgres_forward returns, Postgres answers on 127.0.0.1:$local_port
# and $admin_user / $admin_password hold the instance's master credentials.

region=us-east-2
local_port=15432

shared_postgres_param() {
	aws ssm get-parameter --region "$region" --with-decryption \
		--name "/motifpath/shared/postgres/$1" --query Parameter.Value --output text
}

start_postgres_forward() {
	address=$(shared_postgres_param ADDRESS)
	admin_user=$(shared_postgres_param USERNAME)
	admin_password=$(shared_postgres_param PASSWORD)
	local instance_id
	instance_id=$(terraform -chdir=environments/shared output -raw vm_instance_id)

	command -v session-manager-plugin >/dev/null ||
		{ echo "the Session Manager plugin is not installed" >&2; exit 1; }

	echo "forwarding localhost:$local_port to $address:5432 through $instance_id"
	forward_log=$(mktemp)
	aws ssm start-session --region "$region" --target "$instance_id" \
		--document-name AWS-StartPortForwardingSessionToRemoteHost \
		--parameters "host=$address,portNumber=5432,localPortNumber=$local_port" >"$forward_log" 2>&1 &
	forward=$!
	trap 'kill "$forward" 2>/dev/null || true; rm -f "$forward_log"' EXIT

	local ready=
	for _ in $(seq 30); do
		kill -0 "$forward" 2>/dev/null || forward_failed "the port forward exited"
		if PGPASSWORD=$admin_password pg_isready -q -h 127.0.0.1 -p "$local_port"; then
			ready=1
			break
		fi
		sleep 1
	done
	[[ -n $ready ]] || forward_failed "Postgres did not answer on localhost:$local_port within 30s"
}

forward_failed() {
	echo "$1; port forward output:" >&2
	cat "$forward_log" >&2
	exit 1
}
