#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o xtrace

BUILD_DEPS=(curl)

apt-get update
apt-get -y install "${BUILD_DEPS[@]}"
rm -rf /var/lib/apt/lists/*

FILE="influxdb2-${INFLUXDB_VERSION}-amd64.deb"
URL="https://dl.influxdata.com/influxdb/releases/${FILE}"

wget "${URL}"

echo "${INFLUXDB_DEB_SHA256} ${FILE}" | sha256sum -c

dpkg -i "${FILE}"

if [[ -n "$INFLUX_CLIENT" ]]; then
 FILE="influxdb2-client-2.7.0-linux-amd64.tar.gz"
 URL="https://dl.influxdata.com/influxdb/releases/${FILE}"

 wget "${URL}"

 tar xvzf "$FILE"

 cp ./influx /usr/local/bin/
fi
