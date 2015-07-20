HAProxy container with confd auto-configuration
===============================================

Lighweight container (based on [Alpine](https://github.com/gliderlabs/docker-alpine)) prividing an [HAProxy](http://www.haproxy.org/) server with auto-configuration provided by [confd](http://www.confd.io/)

confd version is hard-coded in the Dockerfile, please edit to upgrade.

To build the container:

```
git clone https://github.com/rjrivero/Dockerfiles.git
docker build -t haproxy-confd .
```

To run:

```
docker run --rm -e ETCD_NODE=http://<HOST>:<PORT> -P --name proxy haproxy-confd
```

The container exposes **port 8080** by default.

Environment variables
---------------------

The container accepts the following environment variables:

  - ETCD_NODE: URL (in the form http://<HOST>:<PORT>) of the ETCD node to which the server should attach.
  - ETCD_PREFIX: ETCD path to be used for configuration keys
  - LOG_HOST: URL of the syslog server to use, in the form <HOST>:<PORT>

The haproxy server is configured by default to enable the statistics page. The following environment variables customize the behaviour oif the stats service:

  - STATS_USER: Username to restrict access to the stats service.
  - STATS_PASSWORD: Password for the stats user
  - STATS_PORT: Port number for the stats service (by default, 5000).

Configuring services
--------------------

Services are configured under the etcd prefix specified by the environment variable **ECTD_PREFIX** (*haproxy-confd* by default). Services accept the following keys:

  - /services/*$SERVICE_NAME*/domain: Host / domain name of the service (may include the port, e.g.: **my.domain.com**)
    - The match is performed against the **beginning**, to avoid problems when the port number is explicitly specified (as in *www.somedomain.com:8080*). As a side effect, you can match on subdomain (e.g. **stats.**)
  - /services/*$SERVICE_NAME*/url_reg: Regular expression matching the path e.g.: **/myapp**)
  - /services/*$SERVICE_NAME*/health: URL to be used for checking health of the backend servers, e.g.: **/ping**)
  - /services/*$SERVICE_NAME*/upstreams/*$SERVER*: Upstream servers' URL, in the form <HOST>:<PORT>
  - /services/*$SERVICE_NAME*/users/*$USERNAME*: Password for each user. If the "users" key does not exist, the backend is not password protected.

