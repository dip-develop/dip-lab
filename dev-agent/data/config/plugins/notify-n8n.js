// notify-n8n: forward opencode session lifecycle events to an n8n webhook
// so the operator gets notified outside the container (n8n routes to
// Telegram/email/etc. -- that part lives in the workflow, not here).
//
// V2 port (opencode.ai/v2/docs/build/plugins/migrate-v1, "Migrate events
// and cleanup"): the old V1 shape -- a default-exported function that
// returns an `event` hook -- does not run under OpenCode 2 at all, per
// that doc's own warning. This uses Plugin.define({ id, setup(ctx) })
// with ctx.event.subscribe() instead. NOT YET RUNTIME-VERIFIED against a
// real V2 build -- ported from the migration doc's own example pattern,
// but confirm in `opencode serve` logs (plugin should appear in the
// active plugin list) before relying on notifications firing.
//
// Auto-loaded as a local plugin: this directory is bind-mounted to
// ~/.config/opencode in the dev-agent container, and V2 discovers every
// plugins/*.js found in ~/.config/opencode/plugins/ at startup.
// Zero imports beyond the plugin API on purpose -- a local plugin with
// npm deps would need a package.json in the config dir and a bun
// install at startup.
//
// Config: N8N_WEBHOOK_URL env var (passed in docker-compose.yml
// `environment:`, value lives in dev-agent/.env). Unset or empty ->
// setup subscribes to nothing and the plugin stays completely inert.
//
// Forwarded events (metadata only -- never message content, so session
// transcripts and anything secret-adjacent cannot leak into n8n):
//   session.idle      an agent finished a turn (review / continue)
//   permission.asked  a session is blocked waiting for approval -- the
//                     one that actually matters in a headless serve
//   session.error     a session blew up mid-run

import { Plugin } from "@opencode/plugin"

const WATCHED = new Set(["session.idle", "permission.asked", "session.error"])

// Allowlist of event.properties fields worth shipping. Anything not
// listed (including free-text/error objects) is dropped.
function pick(props) {
  const out = {}
  if (!props || typeof props !== "object") return out
  for (const key of ["sessionID", "permissionID", "tool", "type"]) {
    const value = props[key]
    if (typeof value === "string" || typeof value === "number") {
      out[key] = value
    }
  }
  return out
}

async function send(webhook, event) {
  let body
  try {
    body = JSON.stringify({
      source: "dip-lab/dev-agent/opencode",
      event: event.type,
      ...pick(event.properties),
      timestamp: new Date().toISOString(),
    })
  } catch {
    return
  }
  try {
    await fetch(webhook, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body,
      // n8n being down/unreachable must never stall the event loop or
      // crash the serve process -- fire, bounded wait, forget.
      signal: AbortSignal.timeout(3000),
    })
  } catch {
    // Notification is best-effort by design; swallow failures.
  }
}

export default Plugin.define({
  id: "notify-n8n",
  setup(ctx) {
    const webhook = process.env.N8N_WEBHOOK_URL
    if (!webhook) return () => {}

    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (WATCHED.has(event.type)) await send(webhook, event)
        }
      } catch {
        // Subscription aborted on cleanup, or the event stream itself
        // errored -- either way, nothing left to do here.
      }
    })()

    return () => controller.abort()
  },
})
