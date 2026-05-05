#!/bin/sh
set -eu

CONFIG_FILE=/usr/share/nginx/html/var/conf/judgels-client.js

js_escape() {
  printf "%s" "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g"
}

mkdir -p "$(dirname "$CONFIG_FILE")"

APP_MODE="${APP_MODE:-JUDGELS}"
APP_NAME="${APP_NAME:-Judgels}"
APP_SLOGAN="${APP_SLOGAN:-Programming Contest System}"
API_URL="${API_URL:-${URL_API:-http://localhost:9101/api/v2}}"
WELCOME_TITLE="${WELCOME_TITLE:-<h1>Welcome to Judgels</h1>}"
WELCOME_DESCRIPTION="${WELCOME_DESCRIPTION:-<h2>This is a programming contest system.</h2>}"
APP_FOOTER="${APP_FOOTER:-Copyright Ikatan Alumni TOKI}"

cat > "$CONFIG_FILE" <<EOF
window.conf = {
  mode: '$(js_escape "$APP_MODE")',
  name: '$(js_escape "$APP_NAME")',
  slogan: '$(js_escape "$APP_SLOGAN")',
  apiUrl: '$(js_escape "$API_URL")',
  welcomeBanner: {
    title: '$(js_escape "$WELCOME_TITLE")',
    description: '$(js_escape "$WELCOME_DESCRIPTION")',
  },
  footer: '$(js_escape "$APP_FOOTER")',
};
EOF
