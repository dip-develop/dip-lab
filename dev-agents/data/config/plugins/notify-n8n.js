// notify-n8n: forward opencode session lifecycle events to an n8n webhook
// so the operator gets notified outside the container (n8n routes to
// Telegram/email/etc. -- that part lives in the workflow, not here).
//
// Auto-loaded as a global plugin: this directory is bind-mounted to
// ~/.config/opencode in the dev-agents container, and opencode loads
// every plugins/*.js found in ~/.config/opencode/plugins/ at startup.
// Zero imports on purpose -- a local plugin with npm deps would need a
// package.json in the config dir and a bun install at startup.
//
// Config: N8N_WEBHOOK_URL env var (passed in docker-compose.yml
// `environment:`, value lives in dev-agents/.env). Unset or empty ->
// the plugin returns no hooks and stays completely inert.
//
// Forwarded events (metadata only -- never message content, so session
// transcripts and anything secret-adjacent cannot leak into n8n):
//   session.idle      an agent finished a turn (review / continue)
//   permission.asked  a session is blocked waiting for approval -- the
//                     one that actually matters in a headless serve
//   session.error     a session blew up mid-run

const webhook = process.env.N8N_WEBHOOK_URL

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

async function send(event) {
  let body
  try {
    body = JSON.stringify({
      source: "dip-lab/dev-agents/opencode",
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
      // n8n being down/unreachable must never stall the event hook or
      // crash the serve process -- fire, bounded wait, forget.
      signal: AbortSignal.timeout(3000),
    })
  } catch {
    // Notification is best-effort by design; swallow failures.
  }
}

const WATCHED = new Set(["session.idle", "permission.asked", "session.error"])

export default async () => {
  if (!webhook) return {}
  return {
    event: async ({ event }) => {
      if (WATCHED.has(event.type)) await send(event)
    },
  }
}
