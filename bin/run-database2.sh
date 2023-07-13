#!/bin/bash
set -o errexit
set -o nounset

TIMEOUT=14

ensure_ssl_material() {
  if [ -n "${SSL_CERTIFICATE:-}" ] && [ -n "${SSL_KEY:-}" ]; then
    # Nothing to do!
    return
  fi

  echo "SSL Material is not present in the environment, auto-generating"
  local keyfile certfile
  certfile="$(mktemp)"
  keyfile="$(mktemp)"

  openssl req -nodes -newkey rsa:2048 -x509 -subj "/CN=influxdb" -out "$certfile" -keyout "$keyfile"
  SSL_CERTIFICATE="$(cat "$certfile")"
  SSL_KEY="$(cat "$keyfile")"
  export SSL_CERTIFICATE SSL_KEY

  rm "$certfile" "$keyfile"
}

ensure_ssl_files() {
  ensure_ssl_material

  SSL_CERTIFICATE_FILE="$(mktemp)"
  echo "$SSL_CERTIFICATE" > "$SSL_CERTIFICATE_FILE"
  unset SSL_CERTIFICATE

  SSL_KEY_FILE="$(mktemp)"
  echo "$SSL_KEY" > "$SSL_KEY_FILE"
  unset SSL_KEY

  chown "${INFLUXDB_USER}:${INFLUXDB_GROUP}" "$SSL_CERTIFICATE_FILE" "$SSL_KEY_FILE"
  echo "SSL_CERTIFICATE_FILE=${SSL_CERTIFICATE_FILE}"
  echo "SSL_KEY_FILE=${SSL_KEY_FILE}"
}

ensure_influxdb_configuration() {
  local host="$1"
  export HOST="${host}"

  ensure_ssl_files

  # Config file MUST be called config.yaml
  INFLUXDB_CONFIGURATION="$(mktemp -d)/config.yaml"
  touch "$INFLUXDB_CONFIGURATION"

  # shellcheck disable=SC2002
  cat "/template/influxdb.yaml.template" \
    | sed "s:__DATA_DIRECTORY__:${DATA_DIRECTORY}:g" \
    | sed "s:__SSL_CERTIFICATE_FILE__:${SSL_CERTIFICATE_FILE}:g" \
    | sed "s:__SSL_KEY_FILE__:${SSL_KEY_FILE}:g" \
    | sed "s:__HOST__:${host}:g" \
    | sed "s:__PORT__:${PORT}:g" \
    > "$INFLUXDB_CONFIGURATION"

  export INFLUXDB_CONFIGURATION

  chown "${INFLUXDB_USER}:${INFLUXDB_GROUP}" "$INFLUXDB_CONFIGURATION"
  chown "${INFLUXDB_USER}:${INFLUXDB_GROUP}" "$(dirname "$INFLUXDB_CONFIGURATION")"
  echo "INFLUXDB_CONFIGURATION=${INFLUXDB_CONFIGURATION}"

  # TODO: GOMAXPROCS
}

create_local_admin_user() {
  local user="$1"
  local password="$2"

  local cmd=(
    influx setup --username "${user}" --password "${password}" --org aptible --bucket "${DATABASE:-db}" \
     --token "${password}" --host "https://${HOST}:${PORT}" --force --skip-verify
  )

  for i in $(seq 0 "$TIMEOUT"); do
    if "${cmd[@]}" 2>/dev/null; then
      return 0
    fi

    echo "[$i] InfluxDB is not responding to queries yet..." >&2
    sleep 1
  done

  # Give it one last chance, so we get log output when we fail.
  "${cmd[@]}"
}

wait_for_exit() {
  local pidFile="$1"

  for i in $(seq 0 "$TIMEOUT"); do
    if [ ! -d /proc/"$pidFile"/ ] ; then
      rm $pidFile
      return 0
    fi

    echo "[$i] InfluxDB has not exited yet..." >&2
    sleep 1
  done

  return 1
}

if [[ "$#" -eq 0 ]]; then
  ensure_influxdb_configuration "0.0.0.0"
  exec sudo -u "$INFLUXDB_USER" -g "$INFLUXDB_GROUP" \
    INFLUXD_CONFIG_PATH="$INFLUXDB_CONFIGURATION" influxd run

elif [[ "$1" == "--initialize" ]]; then
  chown -R "${INFLUXDB_USER}:${INFLUXDB_GROUP}" "$DATA_DIRECTORY"

  ensure_influxdb_configuration "127.0.0.1"

  PID_FILE="$(mktemp)"
  chown "${INFLUXDB_USER}:${INFLUXDB_GROUP}" "$PID_FILE"

  sudo -u "$INFLUXDB_USER" -g "$INFLUXDB_GROUP" \
    INFLUXD_CONFIG_PATH="$INFLUXDB_CONFIGURATION" influxd run &

  echo $! > "$PID_FILE"

  create_local_admin_user "$USERNAME" "$PASSPHRASE"

  kill -TERM "$(cat "$PID_FILE")"
  wait_for_exit "$PID_FILE"

elif [[ "$1" == "--client" ]]; then
  echo "not supported" >&2
  exit 1

elif [[ "$1" == "--dump" ]]; then
  echo "not supported" >&2
  exit 1

elif [[ "$1" == "--restore" ]]; then
  echo "not supported" >&2
  exit 1

elif [[ "$1" == "--readonly" ]]; then
  echo "not supported" >&2
  exit 1

elif [[ "$1" == "--discover" ]]; then
  phrase="$(pwgen -s 32)"
  cat <<EOM
{
  "version": "1.0",
  "environment": {
    "USERNAME": "aptible",
    "DATABASE": "db",
    "ORG": "aptible",
    "PASSPHRASE": "$phrase",
    "TOKEN": "$phrase"
  }
}
EOM

elif [[ "$1" == "--connection-url" ]]; then
  EXPOSE_PORT_PTR="EXPOSE_PORT_${PORT}"

  cat <<EOM
{
  "version": "1.0",
  "credentials": [
    {
      "type": "influxdb",
      "default": true,
      "connection_url": "https://${USERNAME}:${PASSPHRASE}@${EXPOSE_HOST}:${!EXPOSE_PORT_PTR}"
    }
  ]
}
EOM

else
  echo "Unrecognized command: $1"
  exit 1
fi
