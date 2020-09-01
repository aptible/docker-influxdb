# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/influxdb

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/influxdb/status "Docker Repository on Quay.io")](https://quay.io/repository/aptible/influxdb)

InfluxDB, on top of Debian Stetch.

## Installation and Usage

    docker pull quay.io/aptible/influxdb:${VERSION:-latest}

This is an image conforming to the [Aptible database specification](https://support.aptible.com/topics/paas/deploy-custom-database/). To run a server for development purposes, execute

    docker create --name data quay.io/aptible/influxdb
    docker run --volumes-from data -e USERNAME=aptible -e PASSPHRASE=pass -e DATABASE=db quay.io/aptible/influxdb --initialize
    docker run --volumes-from data -P quay.io/aptible/influxdb

The first command sets up a data container named `data` which will hold the configuration and data for the database. The second command creates a InfluxDB instance with a username, passphrase and database name of your choice. The third command starts the database server.

### SSL

The InfluxDB server is configured to enforce SSL for any TCP connection. It uses a self-signed certificate generated at startup time, or a certificate / key pair found in SSL_CERTIFICATE and SSL_KEY.

## Available Versions (Tags)

* `latest`: Currently InfluxDB 1.8
* `1.8`: InfluxDB 1.8
* `1.7`: InfluxDB 1.7
* `1.4`: InfluxDB 1.4

## Tests

Tests are run as part of the `Dockerfile` build. To execute them separately within a container, run:

    bats test

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2020 [Aptible](https://www.aptible.com) and contributors.