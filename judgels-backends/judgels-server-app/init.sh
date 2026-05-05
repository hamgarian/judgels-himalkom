#!/bin/bash

set -e

CONFIG_FILE="${JUDGELS_SERVER_CONFIG_FILE:-var/conf/judgels-server.yml}"

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
  mkdir -p "$(dirname "$CONFIG_FILE")" /var/judgels/data /var/judgels/log

  DB_HOST="$(strip_url_host "${DB_HOST:-localhost}")"
  DB_PORT="${DB_PORT:-3306}"
  DB_NAME="${DB_NAME:-judgels}"
  DB_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true}"
  DB_USER="${SPRING_DATASOURCE_USERNAME:-${DB_USER:-judgels}}"
  DB_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${DB_PASSWORD:-judgels}}"

  RMQ_HOST="$(strip_url_host "${SPRING_RABBITMQ_HOST:-${RMQ_HOST:-}}")"
  RMQ_USER="${SPRING_RABBITMQ_USERNAME:-${RMQ_USER:-guest}}"
  RMQ_PASSWORD="${SPRING_RABBITMQ_PASSWORD:-${RMQ_PASSWORD:-guest}}"

  APP_NAME="${APP_NAME:-Judgels}"
  SUPERADMIN_PASSWORD="${JOPHIEL_SUPERADMIN_INITIAL_PASSWORD:-${SUPERADMIN_PASSWORD:-superadmin}}"
  CORS_ALLOWED_ORIGINS="${JUDGELS_URLS_CLIENT:-${URL_CLIENT:-*}}"

  cat > "$CONFIG_FILE" <<EOF
server:
  applicationConnectors:
    - type: http
      port: 9101

  adminConnectors:
    - type: http
      port: 9111

  requestLog:
    appenders:
      - type: file
        currentLogFilename: /var/judgels/log/judgels-server-request.log
        archivedLogFilenamePattern: /var/judgels/log/judgels-server-request-%d.log.gz
        archivedFileCount: 14

database:
  driverClass: com.mysql.cj.jdbc.Driver
  url: '$(yaml_escape "$DB_URL")'
  user: '$(yaml_escape "$DB_USER")'
  password: '$(yaml_escape "$DB_PASSWORD")'
  properties:
    charSet: UTF-8
    hibernate.dialect: org.hibernate.dialect.MySQLDialect
    hibernate.generate_statistics: false
    hibernate.query.plan_cache_max_size: 64
    hibernate.query.plan_parameter_metadata_max_size: 32

logging:
  appenders:
    - type: console
      threshold: INFO
    - type: file
      currentLogFilename: /var/judgels/log/judgels-server.log
      archivedLogFilenamePattern: /var/judgels/log/judgels-server-%d.log.gz
      archivedFileCount: 14

  loggers:
    org.hibernate.type.BasicTypeRegistry:
      level: OFF

webSecurity:
  cors:
    allowedOrigins: '$(yaml_escape "$CORS_ALLOWED_ORIGINS")'

judgels:
  baseDataDir: /var/judgels/data

  app:
    name: '$(yaml_escape "$APP_NAME")'
EOF

  if [ -n "$RMQ_HOST" ]; then
    cat >> "$CONFIG_FILE" <<EOF

  rabbitmq:
    host: '$(yaml_escape "$RMQ_HOST")'
    username: '$(yaml_escape "$RMQ_USER")'
    password: '$(yaml_escape "$RMQ_PASSWORD")'
EOF
  fi

  cat >> "$CONFIG_FILE" <<EOF

jophiel:
  userResetPassword:
    enabled: false
    requestEmailTemplate:
      subject: Someone requested to reset your password
      body: |
        <p>Dear {{username}},</p>
        <p><a href="${URL_CLIENT:-http://localhost:3000}/reset-password/{{emailCode}}">Click here</a> to reset your password.</p>
    resetEmailTemplate:
      subject: Your password has been reset
      body: |
        <p>Dear {{username}},</p>
        <p>Your password has been reset.</p>

  superadmin:
    initialPassword: '$(yaml_escape "$SUPERADMIN_PASSWORD")'

  session:
    maxConcurrentSessionsPerUser: -1
    disableLogout: false

  web:
    announcements: []

sandalphon:
  gabriel:
    gradingRequestQueueName: gabriel-grading-request
    gradingResponseQueueName: sandalphon-grading-response

uriel:
  gabriel:
    gradingRequestQueueName: gabriel-grading-request
    gradingResponseQueueName: uriel-grading-response

jerahmeel:
  gabriel:
    gradingRequestQueueName: gabriel-grading-request
    gradingResponseQueueName: jerahmeel-grading-response

  stats:
    enabled: false
EOF
}

if [ ! -f "$CONFIG_FILE" ]; then
  write_config
fi

set -x
exec ./bin/judgels-server-app "$@" "$CONFIG_FILE"
