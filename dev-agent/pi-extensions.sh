#!/bin/sh
# Installs the pinned pi extensions into $PI_CODING_AGENT_DIR/extensions/<name>.
#
# This is the local-folder layout that pi and pi-agent-router use. The router
# loads delegated subagent extensions only from there, so `pi install` (which
# puts packages under npm/) is not enough. Each folder carries its own
# node_modules. Idempotent: a folder is rebuilt only when its pinned version
# changes. Runs at container start before the tmux sessions.
set -u
AGENT="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
EXT="$AGENT/extensions"
mkdir -p "$EXT"
FAIL=0

install_one() {
    name=$1
    ver=$2
    dest="$EXT/$name"
    if [ -f "$dest/.pinned-version" ] && [ "$(cat "$dest/.pinned-version")" = "$ver" ]; then
        return 0
    fi
    tmp=$(mktemp -d) || return 1
    if ! (cd "$tmp" && npm pack "$name@$ver" --silent >/dev/null 2>&1); then
        echo "pi-extensions: npm pack $name@$ver failed" >&2
        rm -rf "$tmp"; FAIL=1; return 1
    fi
    rm -rf "$dest" && mkdir -p "$dest"
    tar -xzf "$tmp/$name-$ver.tgz" -C "$dest" --strip-components=1
    if ! (cd "$dest" && npm install --omit=dev --ignore-scripts --no-audit --no-fund >/dev/null 2>&1); then
        echo "pi-extensions: npm install for $name@$ver failed" >&2
        rm -rf "$tmp"; FAIL=1; return 1
    fi
    echo "$ver" > "$dest/.pinned-version"
    rm -rf "$tmp"
    echo "pi-extensions: installed $name@$ver"
}

install_one pi-permission-system 0.8.0
install_one pi-agent-router 0.9.0
install_one pi-sensitive-guard 0.5.0
install_one pi-lens 4.4.4
install_one pi-web-access 0.44.0

# Router config: the router reads config.json from its own folder, so copy the
# repo-managed file there. It is mounted at $AGENT/router-config.json.
if [ -f "$AGENT/router-config.json" ] && [ -d "$EXT/pi-agent-router" ]; then
    cp "$AGENT/router-config.json" "$EXT/pi-agent-router/config.json"
fi

exit $FAIL
