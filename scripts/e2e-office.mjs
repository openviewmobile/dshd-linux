#!/usr/bin/env node
// Ask the running app to convert a local Office file via the office-export-pdf skill.
const port = process.env.CDP_PORT || '9222'
const prompt = process.env.PROMPT || ''
const expect = process.env.EXPECT || 'DONE-PPTX'
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
async function targets() { return (await fetch(`http://127.0.0.1:${port}/json/list`)).json() }
function connect(url) {
  const ws = new WebSocket(url); let id = 0; const pending = new Map()
  ws.addEventListener('message', (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.reject(new Error(JSON.stringify(m.error))) : p.resolve(m.result) } })
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res, { once: true }); ws.addEventListener('error', rej, { once: true }) })
  return { ready, close: () => ws.close(), send(method, params = {}) { return new Promise((resolve, reject) => { const i = ++id; pending.set(i, { resolve, reject }); ws.send(JSON.stringify({ id: i, method, params })) }) } }
}
async function ev(p, expression) {
  const r = await p.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || 'eval failed')
  return r.result?.value
}
const pageInfo = (await targets()).find((t) => t.type === 'page' && t.url.startsWith('dsh-app://'))
if (!pageInfo) { console.error('FAIL: dsh-app page not found'); process.exit(2) }
const p = connect(pageInfo.webSocketDebuggerUrl); await p.ready; await p.send('Runtime.enable')
const typed = await ev(p, `(() => { const b = document.querySelector('[role=textbox]'); if (!b) return false; b.focus(); document.execCommand('insertText', false, ${JSON.stringify(prompt)}); return true })()`)
if (!typed) { console.error('FAIL: no composer'); process.exit(3) }
await sleep(400)
await ev(p, `(() => { const b = document.querySelector('[aria-label="Send message"]'); if (!b) return false; b.click(); return true })()`)
const start = Date.now(); let text = ''
while (Date.now() - start < Number(process.env.TIMEOUT_MS || 180000)) {
  text = await ev(p, 'document.body.innerText')
  if (text.includes(expect)) break
  if (text.includes('Allow once')) { await ev(p, `(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.trim() === 'Allow once'); if (b) b.click(); return true })()`); await sleep(1000) }
  await sleep(2000)
}
console.log(text.includes(expect) ? 'OK ' + expect : 'TIMEOUT')
console.log(text.slice(-1200))
p.close()
process.exit(text.includes(expect) ? 0 : 1)
