#!/usr/bin/env node
/**
 * Minimal Chrome DevTools Protocol client for the packaged Linux desktop app.
 *
 * The Electron app is started with `--remote-debugging-port=<port>` under Xvfb.
 * This helper lets acceptance scripts inspect and drive the real renderer DOM
 * without coordinate-guessing screenshots.
 *
 * Usage (set CDP_PORT, default 9222):
 *   node scripts/cdp.mjs list
 *   node scripts/cdp.mjs eval <page-substring> <expression>
 *   node scripts/cdp.mjs shot <page-substring> <output.png>
 *   node scripts/cdp.mjs click <page-substring> <selector>
 *   node scripts/cdp.mjs type <page-substring> <selector> <text>
 *   node scripts/cdp.mjs key <page-substring> <key> [code]
 *   node scripts/cdp.mjs tap <page-substring> <x> <y>
 *
 * Prefer X11 `import -window root` for screenshots: Page.captureScreenshot can
 * hang for occluded/hidden Electron windows under Xvfb.
 */

import { writeFile } from 'node:fs/promises'

const port = Number(process.env.CDP_PORT ?? 9222)
const [, , command, ...rest] = process.argv

async function targets() {
  const response = await fetch(`http://127.0.0.1:${port}/json/list`)
  if (!response.ok) throw new Error(`CDP target list failed: ${response.status}`)
  return response.json()
}

function pick(list, needle) {
  const match = list.find(target => target.type === 'page'
    && (target.url.includes(needle) || target.title.includes(needle)))
  if (match === undefined) throw new Error(`no page target matching ${JSON.stringify(needle)}`)
  return match
}

async function connect(needle) {
  const target = pick(await targets(), needle)
  const socket = new WebSocket(target.webSocketDebuggerUrl)
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true })
    socket.addEventListener('error', reject, { once: true })
  })
  let nextId = 0
  const pending = new Map()
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data)
    const waiter = pending.get(message.id)
    if (waiter === undefined) return
    pending.delete(message.id)
    if (message.error !== undefined) waiter.reject(new Error(JSON.stringify(message.error)))
    else waiter.resolve(message.result)
  })
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++nextId
    pending.set(id, { resolve, reject })
    socket.send(JSON.stringify({ id, method, params }))
  })
  return { socket, send, target }
}

async function evaluate(send, expression) {
  const result = await send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
    userGesture: true,
  })
  if (result.exceptionDetails !== undefined) {
    throw new Error(result.exceptionDetails.exception?.description ?? result.exceptionDetails.text)
  }
  return result.result.value
}

async function main() {
  if (command === 'list') {
    for (const target of await targets()) {
      console.log(`${target.type}\t${target.title}\t${target.url}`)
    }
    return
  }
  const [needle, ...args] = rest
  if (needle === undefined) throw new Error('missing page substring')
  const { socket, send } = await connect(needle)
  try {
    if (command === 'eval') {
      console.log(await evaluate(send, args[0] ?? 'document.body.innerText'))
    } else if (command === 'shot') {
      const output = args[0]
      if (output === undefined) throw new Error('missing output path')
      const { data } = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false })
      await writeFile(output, Buffer.from(data, 'base64'))
      console.log(output)
    } else if (command === 'click') {
      const selector = args[0]
      console.log(await evaluate(send, `(() => {
        const element = document.querySelector(${JSON.stringify(selector)})
        if (element === null) throw new Error('selector not found: ' + ${JSON.stringify(selector)})
        element.scrollIntoView({ block: 'center' })
        element.click()
        return element.outerHTML.slice(0, 200)
      })()`))
    } else if (command === 'key') {
      const key = args[0]
      const code = args[1] ?? key
      await send('Input.dispatchKeyEvent', { type: 'keyDown', key, code })
      await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code })
      console.log(key)
    } else if (command === 'tap') {
      const x = Number(args[0])
      const y = Number(args[1])
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y })
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 })
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 })
      console.log(`${x},${y}`)
    } else if (command === 'type') {
      const selector = args[0]
      const text = args[1] ?? ''
      console.log(await evaluate(send, `(() => {
        const element = document.querySelector(${JSON.stringify(selector)})
        if (element === null) throw new Error('selector not found: ' + ${JSON.stringify(selector)})
        element.focus()
        const setter = Object.getOwnPropertyDescriptor(
          element instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype,
          'value').set
        setter.call(element, ${JSON.stringify(text)})
        element.dispatchEvent(new Event('input', { bubbles: true }))
        element.dispatchEvent(new Event('change', { bubbles: true }))
        return element.value
      })()`))
    } else {
      throw new Error(`unknown command ${JSON.stringify(command)}`)
    }
  } finally {
    socket.close()
  }
}

main().catch(error => {
  console.error(error.message)
  process.exitCode = 1
})
