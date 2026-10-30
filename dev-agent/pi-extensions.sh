#!/bin/sh
# Installs the pinned pi extensions into $PI_CODING_AGENT_DIR/extensions/<folder>.
#
# This is the local-folder layout pi-subagents loads child extensions from, so `pi install`
# (which puts packages under npm/) is not used. The folder name `subagent` is fixed: pi-subagents
# reads its config from extensions/subagent/config.json. Each folder carries its own
# node_modules. Idempotent: a folder is rebuilt only when its pinned version changes. Runs at
# container start before the tmux sessions.
#
# Host-provided packages (@earendil-works/pi-ai, pi-tui, pi-coding-agent) are never installed here:
# npm is run with --omit=peer, so peers come from the pi host.
#
# Opt-in: PI_REMOTE_PI=1 also installs remote-pi (mobile remote control). It is off by default:
# it bundles its own pi-coding-agent 0.79 and uses a third-party relay unless you set your own.
# See README.
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

# Delegation and permissions. pi-subagents 0.84.0 needs pi >= 1.2.0; pi-permission-system 0.8.0 and
# pi-sensitive-guard 0.5.0 declare pi <= 0.80 peers and are verified on pi 1.4.0 by the smoke test only.
install_one pi-permission-system 0.8.0 pi-permission-system
install_one pi-subagents 0.84.0 subagent
install_one pi-sensitive-guard 0.5.0 pi-sensitive-guard

install_one pi-lens 4.4.5 pi-lens
install_one pi-web-access 0.45.0 pi-web-access
install_one pi-memory 0.4.2 pi-memory
install_one @plannotator/pi-extension 0.28.31 plannotator
install_one @ff-labs/pi-fff 0.11.0 pi-fff

if [ "${PI_REMOTE_PI:-0}" = "1" ]; then
    install_one remote-pi 0.7.0 remote-pi
fi

# pi-subagents reads its config from extensions/subagent/config.json. The file is repo-managed and
# mounted at $AGENT/subagent-config.json; copy it on every start (install_one rebuilds the folder).
if [ -f "$AGENT/subagent-config.json" ] && [ -d "$EXT/subagent" ]; then
    cp "$AGENT/subagent-config.json" "$EXT/subagent/config.json"
fi

exit $FAIL
