#!/bin/sh

if [ -z "$ETCD_NODE" ]
then
  echo "Missing ETCD_NODE env var"
  exit -1
fi

# Escape a string for a sed replace pattern. See:
# http://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern
# USER and PASSWORD deprecated, use the /users key in the service definition
#STATS_USER=`echo "${STATS_USER:-admin}" | sed -e 's/[\/&]/\\&/g'`
#STATS_PASSWORD=`echo "${STATS_PASSWORD:-Changeme!}" | sed -e 's/[\/&]/\\&/g'`
ETCD_KEY=`echo "${ETCD_KEY:-haproxy-confd}"  | sed -e 's/[\/&]/\\&/g'`
STATS_PORT=`echo "${STATS_PORT:-5000}"  | sed -e 's/[\/&]/\\&/g'`
LOG_HOST=`echo "${LOG_HOST:-127.0.0.1}"  | sed -e 's/[\/&]/\\&/g'`

set -eo pipefail

# Copy templates to /usr/local/etcd/confd
mkdir -p /usr/local/etc/confd
mkdir -p /usr/local/etc/confd/templates
mkdir -p /usr/local/etc/confd/conf.d
export IFS='
'

# Move confd files from /etc/confd to /usr/local/etc/confd
for i in /etc/confd/*.toml; do
  cp -f "$i" "/usr/local/$i";
done

# Move confd files from /etc/confd to /usr/local/etc/confd
for i in /etc/confd/templates/*.tmpl; do
  #sed "s/\$STATS_USER/$STATS_USER/g;s/\$STATS_PASSWORD/$STATS_PASSWORD/g;s/\$STATS_PORT/$STATS_PORT/g;s/\$LOG_HOST/$LOG_HOST/g;" \
  sed "s/\$STATS_PORT/$STATS_PORT/g;s/\$LOG_HOST/$LOG_HOST/g;" \
      "$i" > "/usr/local/$i"
done

# Move confd files from /etc/confd to /usr/local/etc/confd
for i in /etc/confd/conf.d/*.toml; do
  sed "s/\$ETCD_PREFIX/$ETCD_PREFIX/g" \
      "$i" > "/usr/local/$i"
done

#confd will start haproxy, since conf will be different than existing (which is null)

echo "[haproxy-confd] booting container. ETCD: $ETCD_NODE"

# Loop until confd has updated the haproxy config
n=0
until confd -confdir /usr/local/etc/confd -onetime -node "$ETCD_NODE"; do
  if [ "$n" -eq "4" ];  then
    echo "Failed to start due to config errors"
    exit -1
  fi
  echo "[haproxy-confd] waiting for confd to refresh haproxy.cfg"
  n=$((n+1))
  sleep $n
done

echo "[haproxy-confd] Initial HAProxy config created. Starting confd"

confd -confdir /usr/local/etc/confd -node "$ETCD_NODE"

