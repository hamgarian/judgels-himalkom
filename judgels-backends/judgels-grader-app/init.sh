#!/bin/bash

set -e

CONFIG_FILE="${JUDGELS_GRADER_CONFIG_FILE:-var/conf/judgels-grader.yml}"

yaml_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

strip_url_host() {
  value="${1#*://}"
  value="${value#*@}"
  value="${value%%/*}"
  value="${value%%:*}"
  printf "%s" "$value"
}

write_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")" /var/judgels/grader/data /var/judgels/grader/cache /var/judgels/grader/log

  RMQ_HOST="$(strip_url_host "${SPRING_RABBITMQ_HOST:-${RMQ_HOST:-localhost}}")"
  RMQ_USER="${SPRING_RABBITMQ_USERNAME:-${RMQ_USER:-guest}}"
  RMQ_PASSWORD="${SPRING_RABBITMQ_PASSWORD:-${RMQ_PASSWORD:-guest}}"
  NUM_WORKER_THREADS="${GABRIEL_GRADING_NUM_WORKER_THREADS:-2}"
  CACHED_BASE_DATA_DIR="${JUDGELS_GRADER_CACHED_BASE_DATA_DIR:-/var/judgels/server/data}"
  SERVER_BASE_DATA_DIR="${JUDGELS_GRADER_SERVER_BASE_DATA_DIR:-localhost:/var/judgels/data}"
  RSYNC_IDENTITY_FILE="${JUDGELS_GRADER_RSYNC_IDENTITY_FILE:-var/conf/judgels-grader}"

  cat > "$CONFIG_FILE" <<EOF
server:
  applicationConnectors:
    - type: http
      port: 9007

logging:
  appenders:
    - type: console
      threshold: INFO
      logFormat: "%-5p [%d{ISO8601,UTC}] [%X{gradingJID:--}]: %m%n%rEx"
    - type: file
      logFormat: "%-5p [%d{ISO8601,UTC}] [%X{gradingJID:--}]: %m%n%rEx"
      currentLogFilename: /var/judgels/grader/log/judgels-grader.log
      archivedLogFilenamePattern: /var/judgels/grader/log/judgels-grader-%d.log.gz
      archivedFileCount: 14

judgels:
  baseDataDir: /var/judgels/grader/data

  rabbitmq:
    host: '$(yaml_escape "$RMQ_HOST")'
    username: '$(yaml_escape "$RMQ_USER")'
    password: '$(yaml_escape "$RMQ_PASSWORD")'

gabriel:
  grading:
    gradingRequestQueueName: gabriel-grading-request
    numWorkerThreads: $NUM_WORKER_THREADS

  cache:
    cachedBaseDataDir: '$(yaml_escape "$CACHED_BASE_DATA_DIR")'
    serverBaseDataDir: '$(yaml_escape "$SERVER_BASE_DATA_DIR")'
    rsyncIdentityFile: '$(yaml_escape "$RSYNC_IDENTITY_FILE")'

  isolate:
    baseDir: /judgels/isolate
EOF
}

if [ ! -f "$CONFIG_FILE" ]; then
  write_config
fi

set -x
exec ./bin/judgels-grader-app "$@" "$CONFIG_FILE"
