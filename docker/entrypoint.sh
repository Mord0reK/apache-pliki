#!/bin/sh
set -e

PUID="${PUID:-911}"
PGID="${PGID:-911}"
TZ="${TZ:-UTC}"

if [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi

group_name="h5ai"
if ! grep -q '^h5ai:' /etc/group; then
    if grep -q ":${PGID}:" /etc/group; then
        group_name="$(grep ":${PGID}:" /etc/group | head -n1 | cut -d: -f1)"
    else
        addgroup -g "${PGID}" -S h5ai
    fi
fi

if ! id -u h5ai >/dev/null 2>&1; then
    adduser -u "${PUID}" -S -G "${group_name}" -H h5ai
fi

mkdir -p /config/nginx /config/h5ai /h5ai

if [ ! -d /config/h5ai/private ]; then
    cp -a /defaults/h5ai/. /config/h5ai/
fi

if [ ! -f /config/nginx/site.conf ]; then
    cp /defaults/nginx/site.conf /config/nginx/site.conf
fi

if [ ! -e /h5ai/_h5ai ]; then
    ln -s /config/h5ai /h5ai/_h5ai
fi

auth_conf="/config/nginx/auth.conf"
if [ "${HTPASSWD}" = "true" ]; then
    HTPASSWD_USER="${HTPASSWD_USER:-h5ai}"
    if [ -n "${HTPASSWD_PW:-}" ]; then
        htpasswd -bc /config/nginx/.htpasswd "${HTPASSWD_USER}" "${HTPASSWD_PW}"
    elif [ -t 0 ]; then
        htpasswd -c /config/nginx/.htpasswd "${HTPASSWD_USER}"
    fi

    if [ -f /config/nginx/.htpasswd ]; then
        cat > "${auth_conf}" <<'EOF'
auth_basic "Restricted";
auth_basic_user_file /config/nginx/.htpasswd;
EOF
    else
        : > "${auth_conf}"
    fi
else
    : > "${auth_conf}"
fi

chown -R "${PUID}:${PGID}" /config /h5ai

exec "$@"
