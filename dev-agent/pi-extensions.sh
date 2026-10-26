#!/bin/sh
# Installs the pinned pi extensions into $PI_CODING_AGENT_DIR/extensions/<folder>.
#
# This is the local-folder layout that pi and pi-agent-router use. The router
# loads delegated subagent extensions only from there, so `pi install` (which
# puts packages under npm/) is not enough. Each folder carries its own
# node_modules. Idempotent: a folder is rebuilt only when its pinned version
# changes. Runs at container start before the tmux sessions.
#
# Host-provided packages (@earendil-works/pi-ai, pi-tui, pi-coding-agent) are
# never installed here: npm is run with --omit=peer, as pi does for its own
# managed packages. Peer packages that are not host-provided (rpiv-i18n) go
# into $AGENT/node_modules, which every extension folder can resolve.
#
# Opt-in: PI_REMOTE_PI=1 also installs remote-pi (mobile remote control). It is
# off by default because it depends on pi ^0.79 and talks to a relay. See README.
set -u
AGENT="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
EXT="$AGENT/extensions"
mkdir -p "$EXT"
FAIL=0

# install_one <npm-spec-name> <version> <folder-name>
install_one() {
    name=$1
    ver=$2
    folder=$3
    dest="$EXT/$folder"
    if [ -f "$dest/.pinned-version" ] && [ "$(cat "$dest/.pinned-version")" = "$ver" ]; then
        return 0
    fi
    tmp=$(mktemp -d) || return 1
    if ! (cd "$tmp" && npm pack "$name@$ver" --silent >/dev/null 2>&1); then
        echo "pi-extensions: npm pack $name@$ver failed" >&2
        rm -rf "$tmp"; FAIL=1; return 1
    fi
    tgz=$(ls "$tmp"/*.tgz 2>/dev/null | head -n 1)
    rm -rf "$dest" && mkdir -p "$dest"
    tar -xzf "$tgz" -C "$dest" --strip-components=1
    if ! (cd "$dest" && npm install --omit=dev --omit=peer --ignore-scripts --no-audit --no-fund >/dev/null 2>&1); then
        echo "pi-extensions: npm install for $name@$ver failed" >&2
        rm -rf "$tmp"; FAIL=1; return 1
    fi
    echo "$ver" > "$dest/.pinned-version"
    rm -rf "$tmp"
    echo "pi-extensions: installed $name@$ver -> $folder"
}

# install_shared_peer <npm-spec-name> <version>: non-host peer, shared by all extensions
install_shared_peer() {
    name=$1
    ver=$2
    if [ -d "$AGENT/node_modules/$name" ] && [ "$(node -p "require('$AGENT/node_modules/$name/package.json').version" 2>/dev/null)" = "$ver" ]; then
        return 0
    fi
    if ! (cd "$AGENT" && npm install --omit=peer --ignore-scripts --no-audit --no-fund "$name@$ver" >/dev/null 2>&1); then
        echo "pi-extensions: shared peer $name@$ver failed" >&2
        FAIL=1; return 1
    fi
    echo "pi-extensions: shared peer $name@$ver"
}

install_one pi-permission-system 0.8.0 pi-permission-system
install_one pi-agent-router 0.9.0 pi-agent-router
install_one pi-sensitive-guard 0.5.0 pi-sensitive-guard
install_one pi-lens 4.4.5 pi-lens
install_one pi-web-access 0.45.0 pi-web-access
install_one pi-memory 0.4.2 pi-memory
install_one @plannotator/pi-extension 0.28.31 plannotator
install_one @ff-labs/pi-fff 0.11.0 pi-fff
install_one @juicesharp/rpiv-todo 2.15.0 rpiv-todo
install_shared_peer @juicesharp/rpiv-i18n 2.15.0

if [ "${PI_REMOTE_PI:-0}" = "1" ]; then
    install_one remote-pi 0.7.0 remote-pi
fi

# Router config: the router reads config.json from its own folder, so copy the
# repo-managed file there. It is mounted at $AGENT/router-config.json.
if [ -f "$AGENT/router-config.json" ] && [ -d "$EXT/pi-agent-router" ]; then
    cp "$AGENT/router-config.json" "$EXT/pi-agent-router/config.json"
fi

exit $FAIL
