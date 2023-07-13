#!/usr/bin/env bats

source "${BATS_TEST_DIRNAME}/test_helpers.sh"

local_s_client() {
  openssl s_client -connect "localhost:${PORT}" "$@" < /dev/null
}

@test "It should allow connections using TLS1.2" {
  start_influxdb

  local_s_client -tls1_2
}

@test "It should allow connections using TLS1.1" {
  start_influxdb

  local_s_client -tls1_1
}

@test "It should allow connections using TLS1.0" {
  start_influxdb

  local_s_client -tls1
}

@test "It should disallow connections using SSLv3" {
  start_influxdb

  ! local_s_client -ssl3
}