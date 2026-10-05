# Dockerfile for dev-agent
#
# General-purpose developer workstation image. opencode is the first agent
# CLI installed in it, not the only one - add other CLIs below without
# renaming anything.
#
# BUILD-TIME ARGS (optional): DEVELOP_UID, DEVELOP_GID - the host user's
# UID/GID so bind-mounted files keep matching ownership. Defaults to
# 1000:1000 if not set (see docker-compose.yml). This image always
# installs OpenCode 2 (via opencode.ai/v2/install); OPENCODE_VERSION
# optionally pins WHICH V2 release to install (e.g. 2.0.3), "latest" by
# default. SERVERPOD_CLI_VERSION pins the serverpod CLI release (default
# 4.0.0). TAILWIND_VERSION pins the Tailwind CSS CLI release (default
# 4.3.3) - a standalone binary, so the version is written WITHOUT the
# leading `v` (the GitHub release tag is `v${TAILWIND_VERSION}`).
# NODE_VERSION pins the Node.js release (default 24.21.0, LTS Krypton)
# installed from the NodeSource apt repo.
# GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL seed the global git identity
# (user.name / user.email) baked into the image -- sourced from
# dev-agent/.env via docker-compose.yml. Flutter (stable) is installed
# in-image, so containers start offline-ready.
#
# Runtime configuration (opencode.jsonc, agents/) is bind-mounted
# from data/config/ on the host - no rebuild required to tweak agent config.

FROM debian:bookworm-slim

ARG DEVELOP_UID=1000
ARG DEVELOP_GID=1000
ARG GIT_AUTHOR_NAME=dev-agent
ARG GIT_AUTHOR_EMAIL=dev-agent@diplab.local

# Base tooling. Nothing here is opencode-specific - the same image could
# host Claude Code, Cursor CLI, etc. Add their deps here later.
#
# Database clients: postgresql-client, default-mysql-client, redis-tools.
# They are installed system-wide so opencode agents can run psql/mysql/
# redis-cli from inside the container. The db-safe wrapper in
# /home/develop/.local/bin intercepts them and refuses to target any
# non-test database (see dev-agent/db-safe.sh).
#
# python3/python3-yaml: agents routinely parse YAML (compose files, CI
# workflows, frontmatter) from a throwaway `python3 -c` one-liner rather
# than installing a parser. python3 was previously present only as an
# *auto* dependency of another package, and anything an agent pip/apt
# installs lands in the container's writable layer -- which
# `./manager.sh update dev-agent` destroys, because a recreate rebuilds
# the container from this image. Installing it here is what makes it
# survive. python3 is listed explicitly because it was never requested
# directly; python3-yaml would pull it in as a dependency anyway, but the
# base block names its tools outright rather than leaning on transitive
# pulls.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git openssh-client tmux unzip xz-utils \
        chromium libglu1-mesa libgtk-3-dev mesa-utils clang cmake \
        ninja-build pkg-config \
        postgresql-client default-mysql-client redis-tools \
        python3 python3-yaml \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Chromium is installed in the base apt block, but flutter doctor and the
# web tooling look for `google-chrome` unless pointed at the binary.
ENV CHROME_EXECUTABLE=/usr/bin/chromium

# GitHub CLI (gh) - required for PR/issue operations from inside the container.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Node.js (LTS) + npm, from the NodeSource apt repo -- deliberately NOT
# from Debian's own apt, which on bookworm only carries nodejs 18.20.4,
# EOL since April 2025, and where npm is only a `Suggests` of that
# package (`apt-cache depends nodejs` lists it under Suggests, not
# Depends): a plain `apt-get install nodejs` there installs no npm at all,
# and Debian's separate npm package is the old 9.2.0~ds1-1. So the apt
# route would bake an unmaintained Node into the image, with no npm beside
# it, and fail the moment a project's package.json asks for a modern
# engine.
# NodeSource republishes the official upstream binaries per release, and
# NODE_VERSION (default 24.21.0, the 24.x LTS codenamed "Krypton",
# shipping npm 11.19.0) picks the exact one. Like the other pins, moving
# it takes a rebuild.
#
# The shape mirrors the GitHub CLI block above: key into
# /usr/share/keyrings, one-line entry in /etc/apt/sources.list.d, then
# apt-get update. Two NodeSource-specific details:
# - The key at https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
#   is ASCII-armored, not a binary OpenPGP keyring, so the file is named
#   .asc: apt reads armored keyrings for signed-by from 1.4 on (bookworm
#   ships 2.6.1) and uses that extension to tell the two formats apart.
#   This is what lets the block keep the `curl | dd` shape instead of
#   pulling in gnupg to `gpg --dearmor`, the way NodeSource's own
#   setup_24.x script does.
# - NodeSource has no per-distribution codename suite. Every Node major
#   gets its own repo whose suite is the literal `nodistro`, so
#   `node_24.x` is hardcoded here and does NOT track NODE_VERSION -- that
#   arg pins the package version INSIDE the 24.x repo instead.
#
# The install appends the deb's Debian revision (`-1nodesource1`) to
# NODE_VERSION because apt matches the full version string: `nodejs=24.21.0`
# on its own fails with "Version '24.21.0' for 'nodejs' was not found". If
# NodeSource ever republishes a release under a different revision this
# build fails loudly here rather than quietly installing something else.
# The `nodejs` package Provides npm, so this one install brings node, npm
# and npx along. Do not try to add npm separately: the NodeSource nodejs
# package Conflicts: npm (and nodejs-doc/-dev/-legacy), so a
# `sudo apt-get install npm` -- the obvious move in an image whose docs
# tell agents to install packages with sudo -- resolves to Debian's npm
# 9.2.0~ds1-1 and REMOVES nodejs. npm is part of this one install.
#
# No ENV PATH line for node: the deb installs into /usr/bin, already on
# PATH from the base image. Nothing global is baked in via npm either.
# npm's global prefix here is /usr, NOT /usr/local: @npmcli/config derives
# it as dirname(dirname(process.execPath)), and the deb's binary is
# /usr/bin/node, so the global dir is /usr/lib/node_modules. That is
# root-owned, which splits a runtime `npm i -g` in two: as the develop
# user it fails outright with EACCES and needs `sudo npm i -g`, and run as
# root it succeeds but lands in the writable layer and dies on recreate,
# exactly like any other runtime install.
#
# The trailing `node --version && npm --version` is a build-time smoke
# test, same idea as the Tailwind one further down: it proves the pin
# resolved and the binaries actually run -- here as root, before the
# develop user exists. npm is checked too because this image advertises
# npm (README, Tailwind note above), and the Conflicts trap above makes a
# missing npm the easy way for the nodejs install to go wrong.
ARG NODE_VERSION=24.21.0
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | dd of=/usr/share/keyrings/nodesource-repo-keyring.asc \
    && chmod go+r /usr/share/keyrings/nodesource-repo-keyring.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource-repo-keyring.asc] https://deb.nodesource.com/node_24.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "nodejs=${NODE_VERSION}-1nodesource1" \
    && rm -rf /var/lib/apt/lists/* \
    && node --version \
    && npm --version

# Create the non-root user. If the host UID/GID are not specified, the
# default 1000:1000 is used. sudo + NOPASSWD is intentional: opencode
# agents use it to install packages/tools inside the container
# (e.g. `sudo apt-get install <pkg>`). no-new-privileges is therefore
# deliberately NOT set in docker-compose.yml, since it would block
# setuid elevation and make sudo unusable.
RUN groupadd -g ${DEVELOP_GID} develop \
    && useradd -m -u ${DEVELOP_UID} -g ${DEVELOP_GID} -s /bin/bash develop \
    && usermod -aG sudo develop \
    && echo 'develop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/develop \
    && mkdir -p /home/develop/.local/bin \
    && chown -R develop:develop /home/develop/.local

# Pre-create state dirs that will be backed by named volumes in
# docker-compose.yml. If they don't exist in the image, Docker creates
# the mountpoint as root:root and the develop user could not write to
# them. Copy-on-first-use then seeds the volumes with these
# (owned-by-develop) directories.
# NOTE: .pub-cache is intentionally omitted here - it is created later
# by the `dart pub global activate` block below, which also seeds the
# named volume with the global Dart CLIs baked at build time.
RUN mkdir -p /home/develop/.ssh /home/develop/.local/share/opencode \
             /home/develop/.dartServer /home/develop/.dart-tool \
    && chmod 700 /home/develop/.ssh \
    && chown -R develop:develop /home/develop/.ssh \
             /home/develop/.local/share/opencode \
             /home/develop/.dartServer /home/develop/.dart-tool

USER develop
WORKDIR /home/develop

# Sane global git defaults baked into the image. Identity (user.name /
# user.email) comes from the GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL build
# args (sourced from dev-agent/.env) so `git config user.name` and
# `git config user.email` return real values even after a clean
# container start. The GIT_AUTHOR_* / GIT_COMMITTER_* runtime env vars
# still override the author/committer on individual commits. These
# defaults survive container recreation for free since they live in the
# image, not in container state.
RUN git config --global init.defaultBranch main \
    && git config --global push.autoSetupRemote true \
    && git config --global fetch.prune true \
    && git config --global pull.rebase true \
    && git config --global user.name "$GIT_AUTHOR_NAME" \
    && git config --global user.email "$GIT_AUTHOR_EMAIL"

# `db-safe` wrapper - shadows psql, mysql, mariadb, redis-cli.
# Refuses to talk to a non-test database unless the operator has
# explicitly set DB_SAFETY_GUARD=false. See dev-agent/db-safe.sh
# for the full rule list. Installed into the develop user's bin
# dir, which comes first on PATH (set below).
COPY db-safe.sh /home/develop/.local/bin/db-safe
RUN for tool in psql mysql mariadb redis-cli; do \
        ln -sf /home/develop/.local/bin/db-safe \
               /home/develop/.local/bin/$tool; \
    done

ENV PATH="/home/develop/.local/bin:${PATH}"

# opencode - the first agent CLI in this box, not the only one.
# Add more CLI installs here later without touching anything above.
# Always uses the V2 installer (opencode.ai/v2/install). Pin with
# OPENCODE_VERSION (e.g. 2.0.3 -- a real V2 release string) for
# reproducible builds; "latest" (default) installs the current V2
# release. NOT VERIFIED: the V1 installer's --version flag is assumed to
# carry over to V2 unchanged (same project, same install-script shape) --
# confirm with `bash -s -- --help` against the V2 installer before
# relying on a pin for a real build.
ARG OPENCODE_VERSION=latest
RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
        curl -fsSL https://opencode.ai/v2/install | bash; \
    else \
        curl -fsSL https://opencode.ai/v2/install | bash -s -- --version "$OPENCODE_VERSION"; \
    fi
ENV PATH="/home/develop/.opencode/bin:${PATH}"

# Standalone Dart SDK (stable channel) - kept independent of the Flutter
# checkout below so pure-Dart projects (Serverpod, CLIs) get a `dart` on
# PATH that does not depend on Flutter. Flutter still uses its own bundled
# Dart via its launcher. Pin with DART_VERSION (e.g. 3.5.4); "latest"
# (default) installs the current stable release.
ARG DART_VERSION=latest
ARG TARGETARCH
RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) DART_ARCH=x64 ;; \
        arm64) DART_ARCH=arm64 ;; \
        *) echo "ERROR: unsupported TARGETARCH '${TARGETARCH}' for the Dart SDK (expected amd64 or arm64)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/dartsdk.zip \
        "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-${DART_ARCH}-release.zip" \
    && sudo unzip -q /tmp/dartsdk.zip -d /opt \
    && rm /tmp/dartsdk.zip
ENV PATH="/opt/dart-sdk/bin:${PATH}"

# Global Dart CLIs, installed with the standalone Dart SDK (runs as the
# develop user; binaries land in /home/develop/.pub-cache/bin).
# - skills: per-project AI skills installer; only the CLI is baked in
#   (`skills get <pkg>` is run inside projects at runtime, not at build).
# - serverpod CLI: pinned via SERVERPOD_CLI_VERSION — provides `serverpod`
#   and `serverpod language-server`.
# - serverpod_mcp: separate package providing the `serverpod_mcp` binary
#   referenced by the mcp block in opencode.jsonc.
# - jaspr CLI: provides `jaspr` (create/serve/build).
ARG SERVERPOD_CLI_VERSION=4.0.0
RUN dart pub global activate skills \
    && dart pub global activate serverpod_cli "$SERVERPOD_CLI_VERSION" \
    && dart pub global activate serverpod_mcp \
    && dart pub global activate jaspr_cli
# Exported at image level (not just .bashrc) so opencode serve, its bash
# tool, and docker exec see the binaries without a login shell.
ENV PATH="/home/develop/.pub-cache/bin:${PATH}"

# Flutter SDK (stable channel). Cloned as the develop user so the flutter
# tool can write its cache/version files next to the SDK. `flutter
# --version` warms the Dart SDK + artifacts cache into the image so
# containers start offline-ready.
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /home/develop/flutter \
    && /home/develop/flutter/bin/flutter --version \
    && /home/develop/flutter/bin/flutter config --no-analytics \
    && /home/develop/flutter/bin/flutter precache --universal --linux --web
# Appended (not prepended) so the standalone Dart SDK above intentionally
# shadows Flutter's bundled dart shim. Safe: the flutter launcher always
# uses its own bundled SDK regardless of PATH order.
ENV PATH="${PATH}:/home/develop/flutter/bin"

# Tailwind CSS CLI (v4 standalone binary) - the CSS engine behind the
# jaspr/Web tooling. The image does ship Node.js + npm (see the NodeSource
# block above), so `npm i -D @tailwindcss/cli` and the on-demand
# `npx @tailwindcss/cli` both work here. The standalone release binary is
# still the deliberate choice, for reasons that have nothing to do with npm
# being absent:
# - it is a single self-contained executable at a fixed path
#   (/opt/tailwindcss/tailwindcss) with no dependency on where npm's global
#   prefix lands or how that prefix is later reconfigured;
# - it cannot be broken or removed by an npm operation inside a project --
#   no shared node_modules or package-lock is involved;
# - it does not add a second, independently-versioned copy of Node to the
#   image.
# Pin with TAILWIND_VERSION (e.g. 4.3.3), written WITHOUT the leading `v` -
# the GitHub release tag is `v${TAILWIND_VERSION}`.
#
# Installed in-image for the same reason python3 is above: anything
# downloaded into the container's writable layer dies on
# `./manager.sh update dev-agent`, which recreates the container from
# this image. /opt/tailwindcss rather than ~/.local/bin matches the
# /opt/dart-sdk precedent above and keeps a ~110MB binary out of
# ~/.local/bin, the dir holding the db-safe wrapper symlinks. The ENV
# PATH line below prepends /opt/tailwindcss even ahead of
# ~/.local/bin, but ordering only matters for shadowing and there is
# nothing to shadow: the dir holds just the one binary. Root-owned
# 0755: an unprivileged process cannot replace the binary - though
# develop has NOPASSWD sudo in this image (see above), so nothing baked
# in here is truly immutable.
#
# The build-time smoke test is `tailwindcss --help` because v4 has no
# --version flag, and it uses the ABSOLUTE path because the ENV PATH
# line exposing /opt/tailwindcss is declared AFTER this RUN: a bare
# `tailwindcss` on this line is not on PATH yet, so it would fail as
# "command not found" rather than print help.
#
# The cwd matters as much as the PATH here: bare `tailwindcss` in a
# non-TTY context falls through to the build path, whose source
# auto-detection scans the cwd recursively. WORKDIR is /home/develop at
# this point, and the Flutter checkout cloned above lives inside it as a
# subdirectory (/home/develop/projects only becomes the cwd at the
# WORKDIR line below), so reach for the absolute path whenever a build
# runs from here.
ARG TAILWIND_VERSION=4.3.3
RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) TAILWIND_ARCH=x64 ;; \
        arm64) TAILWIND_ARCH=arm64 ;; \
        *) echo "ERROR: unsupported TARGETARCH '${TARGETARCH}' for the Tailwind CSS CLI (expected amd64 or arm64)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/tailwindcss \
        "https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWIND_VERSION}/tailwindcss-linux-${TAILWIND_ARCH}" \
    && sudo install -d -m 0755 /opt/tailwindcss \
    && sudo install -m 0755 /tmp/tailwindcss /opt/tailwindcss/tailwindcss \
    && rm /tmp/tailwindcss \
    && /opt/tailwindcss/tailwindcss --help > /dev/null
ENV PATH="/opt/tailwindcss:${PATH}"

# Bash profile snippet that exports the test-cred env vars into
# every interactive shell. The file is sourced from ~/.bashrc (added
# below). Variables match the names in .env.example and are forwarded
# from the container's environment by docker-compose.
RUN mkdir -p /home/develop/.config/dev-agent \
    && cat > /home/develop/.config/dev-agent/env.sh <<'EOF'
# Auto-generated by Dockerfile. Mirrors the container's environment
# into the interactive shell so psql/mysql/redis-cli pick up the
# test credentials without manual `export` calls.
export PGPASSWORD="$TEST_POSTGRES_PASSWORD"
export MYSQL_PWD="$TEST_MYSQL_PASSWORD"
export REDISCLI_AUTH="$TEST_REDIS_PASSWORD"
export PGUSER="$TEST_POSTGRES_USER"
export MYSQL_USER="$TEST_MYSQL_USER"
EOF
RUN printf '\n# dev-agent test-DB env\n[ -f ~/.config/dev-agent/env.sh ] && . ~/.config/dev-agent/env.sh\n' \
        >> /home/develop/.bashrc

# Toolchain PATH for interactive shells. The image ENV above already
# exports these for every process, but login shells and `su - develop`
# reset PATH, so re-export here. Order mirrors the ENV lines: the
# standalone Dart SDK and the Tailwind CSS CLI dir are prepended, so
# they shadow anything on the inherited PATH; Flutter's launcher dir is
# appended (keeping the standalone `dart` ahead of Flutter's bundled
# shim), then the pub-global and Dart-managed install dirs
# (pre-populated at build time by the global CLI installs above /
# IDE tooling).
RUN printf '\n# dev-agent toolchain PATH\nexport PATH="/opt/dart-sdk/bin:$PATH"\nexport PATH="/opt/tailwindcss:$PATH"\nexport PATH="$PATH:/home/develop/flutter/bin"\nexport PATH="$PATH":"$HOME/.local/state/Dart/install/bin"\nexport PATH="$PATH":"$HOME/.pub-cache/bin"\n# Flutter web tooling: point flutter doctor / chrome driver at the apt-installed chromium.\nexport CHROME_EXECUTABLE="/usr/bin/chromium"\n' \
        >> /home/develop/.bashrc

WORKDIR /home/develop/projects

# `opencode serve` runs as the container's main process. A detached
# tmux session starts first and stays up independently so you can still
# drop into a shell:  docker exec -it dev-agent tmux attach -t dev
#
# The port binding (0.0.0.0 inside the container) is fine - the
# host-side restriction happens via the ports: mapping in
# docker-compose.yml (default 127.0.0.1:4096:4096).
ENTRYPOINT ["/bin/sh", "-c", "tmux new-session -d -s dev && exec opencode serve --hostname 0.0.0.0 --port 4096"]
