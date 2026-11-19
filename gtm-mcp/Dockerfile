# gtm-mcp: Google Tag Manager MCP server, self-hosted.
#
# Upstream (github.com/paolobietolini/gtm-mcp-server) publishes no container
# image - .goreleaser.yaml builds archives only - so this wraps its released
# static binary instead of compiling the Go source in a builder stage.
#
# The release tarball is verified against the checksums.txt published with the
# same release, and the version is pinned via GTM_MCP_VERSION, so a rebuild
# reproduces the same server.
#
# Why self-hosted: the public instance at https://mcp.gtmeditor.com is shut
# down on 2026-11-30, and it is the only instance upstream offers.

FROM alpine:3.21

ARG GTM_MCP_VERSION=1.13.0
ARG TARGETARCH

# ca-certificates: outbound HTTPS to the Google APIs. tzdata: timestamps in
# logs. wget and sha256sum come from busybox.
RUN apk add --no-cache ca-certificates tzdata

RUN set -eux; \
    case "$TARGETARCH" in \
        amd64) GTM_ARCH=amd64 ;; \
        arm64) GTM_ARCH=arm64 ;; \
        *) echo "ERROR: unsupported TARGETARCH '${TARGETARCH}' (expected amd64 or arm64)" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/paolobietolini/gtm-mcp-server/releases/download/v${GTM_MCP_VERSION}"; \
    asset="gtm-mcp-server_${GTM_MCP_VERSION}_linux_${GTM_ARCH}.tar.gz"; \
    wget -O "/tmp/${asset}" "${base}/${asset}"; \
    wget -O /tmp/checksums.txt "${base}/gtm-mcp-server_${GTM_MCP_VERSION}_checksums.txt"; \
    ( cd /tmp && grep " ${asset}\$" checksums.txt | sha256sum -c - ); \
    tar -xzf "/tmp/${asset}" -C /tmp; \
    mkdir -p /opt/gtm-mcp; \
    cp /tmp/gtm-mcp-server /opt/gtm-mcp/gtm-mcp-server; \
    chmod 0755 /opt/gtm-mcp/gtm-mcp-server; \
    rm -rf "/tmp/${asset}" /tmp/checksums.txt /tmp/gtm-mcp-server

# Non-root, matching the upstream image's appuser posture.
RUN adduser -D -g '' -u 10001 appuser
USER appuser
WORKDIR /opt/gtm-mcp

ENV PORT=8080
EXPOSE 8080

# Same probe the upstream image uses.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/health || exit 1

ENTRYPOINT ["/opt/gtm-mcp/gtm-mcp-server"]