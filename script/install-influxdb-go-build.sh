#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o xtrace

export GOPATH=/gopath
export GOROOT=/goroot
export PATH="$PATH:$GOROOT/bin"

BUILD_DEPS=(git python curl)

apt-get update
apt-get -y install "${BUILD_DEPS[@]}"
rm -rf /var/lib/apt/lists/*

GO_FILENAME="go${GO_VERSION}.linux-amd64.tar.gz"

cd /tmp
curl -fsSLO "https://storage.googleapis.com/golang/${GO_FILENAME}"
echo "${GO_SHA256SUM} ${GO_FILENAME}" | sha256sum -c
tar xzf "$GO_FILENAME"
mv go "$GOROOT"
rm "$GO_FILENAME"


PKG="github.com/influxdata/influxdb"
REF="v${INFLUXDB_VERSION}"
go get "$PKG"
cd "${GOPATH}/src/${PKG}"

git checkout "$REF"
python build.py -o /usr/local/bin

cd /

rm -r "$GOPATH" "$GOROOT"

apt-get -y remove "${BUILD_DEPS[@]}"
apt-get -y autoremove
