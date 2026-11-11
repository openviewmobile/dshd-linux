import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const CHROME = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const FPS = Number(process.env.FPS || 30);
const DURATION = Number(process.env.DURATION || 50);
const WIDTH = 1920;
const HEIGHT = 1080;
const OUT = path.join(ROOT, 'frames');
const THUMB = path.join(ROOT, 'out', 'dshd-linux-thumbnail.png');
fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(path.dirname(THUMB), { recursive: true });

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://127.0.0.1');
  const rel = decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname);
  const file = path.join(ROOT, rel);
  if (!file.startsWith(ROOT) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404); res.end('not found'); return;
  }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
  fs.createReadStream(file).pipe(res);
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const port = server.address().port;

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-dev-shm-usage',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    '--font-render-hinting=none',
    '--ignore-gpu-blocklist',
    '--enable-webgl',
  ],
});
const page = await browser.newPage();
await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 1 });
page.on('console', msg => { if (msg.type() === 'error') console.error('PAGE:', msg.text()); });
page.on('pageerror', err => console.error('PAGEERROR:', err.message));
await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: 'networkidle0', timeout: 60000 });
await page.waitForFunction(() => document.body.dataset.ready === '1', { timeout: 30000 });
await page.evaluate(() => document.fonts.ready);

const total = Math.round(FPS * DURATION);
const THUMB_ONLY = process.env.THUMB_ONLY === '1';
console.log(THUMB_ONLY ? 'Rendering thumbnail only' : `Rendering ${total} frames at ${WIDTH}x${HEIGHT}@${FPS}fps`);

for (let i = 0; i < total && !THUMB_ONLY; i++) {
  const t = i / FPS;
  await page.evaluate((time) => window.renderAt(time), t);
  const name = `frame_${String(i + 1).padStart(5, '0')}.jpg`;
  await page.screenshot({ path: path.join(OUT, name), type: 'jpeg', quality: 95, optimizeForSpeed: true });
  if ((i + 1) % 90 === 0 || i === total - 1) {
    process.stdout.write(`  ${i + 1}/${total}\n`);
  }
}

await page.evaluate(() => { document.body.classList.add('thumb'); window.renderAt(49.5); });
await page.screenshot({ path: THUMB, type: 'png', optimizeForSpeed: true });
console.log(`Thumbnail: ${THUMB}`);

await browser.close();
server.close();
