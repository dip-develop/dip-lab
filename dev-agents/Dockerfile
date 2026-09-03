# Dockerfile for dev-agents
#
# General-purpose developer workstation image. opencode is the first agent
# CLI installed in it, not the only one - add other CLIs below without
# renaming anything.
#
# BUILD-TIME ARGS (optional): DEVELOP_UID, DEVELOP_GID - the host user's
# UID/GID so bind-mounted files keep matching ownership. Defaults to
# 1000:1000 if not set (see docker-compose.yml). OPENCODE_VERSION pins
# the opencode CLI release ("latest" by default). Flutter (stable) is
# installed in-image, so containers start offline-ready.
#
# Runtime configuration (opencode.jsonc, agents/) is bind-mounted
# from data/config/ on the host - no rebuild required to tweak agent config.

FROM debian:bookworm-slim

ARG DEVELOP_UID=1000
ARG DEVELOP_GID=1000

# Base tooling. Nothing here is opencode-specific - the same image could
# host Claude Code, Cursor CLI, etc. Add their deps here later.
#
# Database clients: postgresql-client, default-mysql-client, redis-tools.
# They are installed system-wide so opencode agents can run psql/mysql/
# redis-cli from inside the container. The db-safe wrapper in
# /home/develop/.local/bin intercepts them and refuses to target any
# non-test database (see dev-agents/db-safe.sh).
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git openssh-client tmux unzip xz-utils \
        chromium libglu1-mesa clang cmake ninja-build pkg-config \
        postgresql-client default-mysql-client redis-tools \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (gh) - required for PR/issue operations from inside the container.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

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

USER develop
WORKDIR /home/develop

# `db-safe` wrapper - shadows psql, mysql, mariadb, redis-cli.
# Refuses to talk to a non-test database unless the operator has
# explicitly set DB_SAFETY_GUARD=false. See dev-agents/db-safe.sh
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
# Pin with OPENCODE_VERSION (e.g. 1.0.180) for reproducible builds.
# "latest" (default) installs the current release.
ARG OPENCODE_VERSION=latest
RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
        curl -fsSL https://opencode.ai/install | bash; \
    else \
        curl -fsSL https://opencode.ai/install | bash -s -- --version "$OPENCODE_VERSION"; \
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

# Bash profile snippet that exports the test-cred env vars into
# every interactive shell. The file is sourced from ~/.bashrc (added
# below). Variables match the names in .env.example and are forwarded
# from the container's environment by docker-compose.
RUN mkdir -p /home/develop/.config/dev-agents \
    && cat > /home/develop/.config/dev-agents/env.sh <<'EOF'
# Auto-generated by Dockerfile. Mirrors the container's environment
# into the interactive shell so psql/mysql/redis-cli pick up the
# test credentials without manual `export` calls.
export PGPASSWORD="$TEST_POSTGRES_PASSWORD"
export MYSQL_PWD="$TEST_MYSQL_PASSWORD"
export REDISCLI_AUTH="$TEST_REDIS_PASSWORD"
export PGUSER="$TEST_POSTGRES_USER"
export MYSQL_USER="$TEST_MYSQL_USER"
EOF
RUN printf '\n# dev-agents test-DB env\n[ -f ~/.config/dev-agents/env.sh ] && . ~/.config/dev-agents/env.sh\n' \
        >> /home/develop/.bashrc

WORKDIR /home/develop/projects

# `opencode serve` runs as the container's main process. A detached
# tmux session starts first and stays up independently so you can still
# drop into a shell:  docker exec -it dev-agents tmux attach -t dev
#
# The port binding (0.0.0.0 inside the container) is fine - the
# host-side restriction happens via the ports: mapping in
# docker-compose.yml (default 127.0.0.1:4096:4096).
ENTRYPOINT ["/bin/sh", "-c", "tmux new-session -d -s dev && exec opencode serve --hostname 0.0.0.0 --port 4096"]
