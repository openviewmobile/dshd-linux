#!/usr/bin/env node
// Drive a packaged Linux build over CDP and verify a real provider round-trip.
// Usage: CDP_PORT=9222 EXPECT=DSHD-LINUX-PROVIDER-OK node scripts/e2e-provider.mjs
// The app must already be running with --remote-debugging-port=$CDP_PORT.
const port = process.env.CDP_PORT || '9222'
const expect = process.env.EXPECT || '391'
const prompt =
  process.env.PROMPT ||
  '请只回复一行：DSHD-LINUX-PROVIDER-OK，然后写出 17*23 的结果。'
const timeoutMs = Number(process.env.TIMEOUT_MS || 180000)

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function targets() {
  const res = await fetch(`http://127.0.0.1:${port}/json/list`)
  return res.json()
}

async function findPage(predicate, waitMs = 30000) {
  const deadline = Date.now() + waitMs
  while (Date.now() < deadline) {
    for (const t of await targets()) {
      if (t.type === 'page' && predicate(t)) return t
    }
    await sleep(500)
  }
  return null
}

function connect(url) {
  const ws = new WebSocket(url)
  let id = 0
  const pending = new Map()
  ws.addEventListener('message', (event) => {
    const msg = JSON.parse(event.data)
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id)
      pending.delete(msg.id)
      msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result)
    }
  })
  const ready = new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve, { once: true })
    ws.addEventListener('error', reject, { once: true })
  })
  return {
    ready,
    close: () => ws.close(),
    send(method, params = {}) {
      return new Promise((resolve, reject) => {
        const msgId = ++id
        pending.set(msgId, { resolve, reject })
        ws.send(JSON.stringify({ id: msgId, method, params }))
      })
    },
  }
}

async function evalIn(page, expression) {
  const res = await page.send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  })
  if (res.exceptionDetails) {
    throw new Error(res.exceptionDetails.exception?.description || 'evaluate failed')
  }
  return res.result?.value
}

const welcome = await findPage((t) => t.url.includes('welcome.html'), 5000)
if (welcome) {
  const p = connect(welcome.webSocketDebuggerUrl)
  await p.ready
  await evalIn(
    p,
    `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.trim() === 'Set up later'); if (b) b.click(); return true })()`,
  )
  p.close()
  await sleep(1500)
}

const app = await findPage((t) => t.url.startsWith('dsh-app://'))
if (!app) {
  console.error('FAIL: dsh-app page not found')
  process.exit(2)
}

const page = connect(app.webSocketDebuggerUrl)
await page.ready
await page.send('Runtime.enable')

// A fresh home starts on the workspace chooser; pick $HOME so a composer exists.
const hasComposer = await evalIn(page, `!!document.querySelector('[aria-label^="Select model"]')`)
if (!hasComposer) {
  await evalIn(
    page,
    `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.includes('Choose workspace')); if (b) b.click(); return true })()`,
  )
  await sleep(2000)
  await evalIn(
    page,
    `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.trim() === 'Home'); if (b) b.click(); return true })()`,
  )
  await sleep(1000)
  await evalIn(
    page,
    `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.trim() === 'Open'); if (b) b.click(); return true })()`,
  )
  await sleep(5000)
}

let model = ''
for (let i = 0; i < 30; i++) {
  model = await evalIn(
    page,
    `(() => { const el = document.querySelector('[aria-label^="Select model"]'); return el ? (el.getAttribute('aria-label') || el.innerText).trim() : '' })()`,
  )
  if (model && model !== 'Select model') break
  await sleep(1000)
}
if (!model || model === 'Select model') {
  console.error('FAIL: no model available (provider config missing or not loaded)')
  process.exit(3)
}

const typed = await evalIn(
  page,
  `(() => {
    const box = document.querySelector('[role=textbox]');
    if (!box) return false;
    box.focus();
    document.execCommand('insertText', false, ${JSON.stringify(prompt)});
    return true;
  })()`,
)
if (!typed) {
  console.error('FAIL: composer not found')
  process.exit(4)
}
await sleep(500)
await evalIn(
  page,
  `(() => { const b = document.querySelector('[aria-label="Send message"]'); if (!b) return false; b.click(); return true })()`,
)

const started = Date.now()
let text = ''
while (Date.now() - started < timeoutMs) {
  text = await evalIn(page, 'document.body.innerText')
  if (text.includes(expect) && text.includes('DSHD-LINUX-PROVIDER-OK') && text.includes('Completed')) break
  // The app's own approval UI may hold the call; report it rather than hang silently.
  if (text.includes('Allow once')) {
    await evalIn(
      page,
      `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.trim() === 'Allow once'); if (b) b.click(); return true })()`,
    )
  }
  await sleep(2000)
}
const elapsed = Math.round((Date.now() - started) / 1000)
const ok = text.includes(expect) && text.includes('DSHD-LINUX-PROVIDER-OK') && text.includes('Completed')
console.log(
  JSON.stringify(
    { ok, expect, elapsedSeconds: elapsed, model: model.replace(/\\s+/g, ' '), tail: text.slice(-600) },
    null,
    2,
  ),
)
page.close()
process.exit(ok ? 0 : 1)
