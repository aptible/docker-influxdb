#!/usr/bin/env bats

source "${BATS_TEST_DIRNAME}/test_helpers.sh"

@test "It initializes and runs InfluxDB" {
  start_influxdb
}

@test "It writes data" {
  start_influxdb
  
  utcNow="$(TZ=UTC date "+%s")"

  curl -k -fsSL "https://localhost:${PORT}/write?db=${DATABASE}" \
    -u "${USERNAME}:${PASSPHRASE}" \
    --data-binary "series,foo=bar value=123 ${utcNow}"
}

@test "It uses a consistent user/group ID for influx" {
  run id influxdb

  [ $output == "uid=999(influxdb) gid=999(influxdb) groups=999(influxdb)" ] 
}
