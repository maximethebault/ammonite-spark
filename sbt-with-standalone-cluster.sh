#!/usr/bin/env bash
set -e

SPARK_VERSION="2.3.2"
HOST=localhost

cd "$(dirname "${BASH_SOURCE[0]}")"

CACHE="${STANDALONE_CACHE:-"$(pwd)/target/standalone"}"

mkdir -p "$CACHE"

# Fetch spark distrib
if [ ! -d "$CACHE/spark-$SPARK_VERSION-"* ]; then
  TRANSIENT_SPARK_ARCHIVE=0
  if [ ! -e "$CACHE/archive/spark-$SPARK_VERSION-"*.tgz ]; then
    mkdir -p "$CACHE/archive"
    TRANSIENT_SPARK_ARCHIVE=1
    curl -Lo "$CACHE/archive/spark-$SPARK_VERSION-bin-hadoop2.7.tgz" "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz"
  fi

  ( cd "$CACHE" && tar -zxvf "archive/spark-$SPARK_VERSION-"*.tgz )
  test "$TRANSIENT_SPARK_ARCHIVE" = 0 || rm -f "$CACHE/archive/spark-$SPARK_VERSION-"*.tgz
  rmdir -p "$CACHE/archive" 2>/dev/null || true
fi


cleanup() {
  cd "$CACHE/spark-$SPARK_VERSION-"*
  sbin/stop-slave.sh || true
  sbin/stop-master.sh || true
}

trap cleanup EXIT INT TERM


SPARK_MASTER="spark://$HOST:7077"

cd "$CACHE/spark-$SPARK_VERSION-"*
sbin/start-master.sh --host "$HOST"
sbin/start-slave.sh --host "$HOST" "$SPARK_MASTER" -c 4 -m 4g
cd -

STANDALONE_SPARK_MASTER="$SPARK_MASTER" \
  STANDALONE_SPARK_VERSION="$SPARK_VERSION" \
  sbt "$@"
