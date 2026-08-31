// Pengemudi peramban untuk uji end-to-end.
//
// Situs ini statis, jadi tidak ada kerangka uji yang perlu dipasang: cukup
// server berkas kecil, Chrome headless, dan protokol DevTools. Tidak ada
// dependensi npm sama sekali, sehingga uji ini ikut berjalan di CI tanpa
// langkah pemasangan tambahan.
import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { join, extname, resolve } from "node:path";

const TIPE = {
  ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript",
  ".json": "application/json", ".webp": "image/webp", ".svg": "image/svg+xml",
  ".jpg": "image/jpeg", ".png": "image/png", ".woff2": "font/woff2", ".xml": "application/xml",
  ".txt": "text/plain", ".webmanifest": "application/manifest+json",
};

export async function serve(root, port = 0) {
  const dir = resolve(root);
  const server = createServer(async (req, res) => {
    try {
      let path = join(dir, decodeURIComponent(req.url.split("?")[0]));
      if ((await stat(path).catch(() => null))?.isDirectory()) path = join(path, "index.html");
      const body = await readFile(path);
      res.writeHead(200, { "content-type": TIPE[extname(path)] || "application/octet-stream" });
      res.end(body);
    } catch {
      res.writeHead(404, { "content-type": "text/html" });
      res.end("<!doctype html><title>404</title>");
    }
  });
  await new Promise((r) => server.listen(port, "127.0.0.1", r));
  return { server, base: `http://127.0.0.1:${server.address().port}`, close: () => server.close() };
}

const CHROME_PATHS = [
  process.env.CHROME_PATH,
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
  "/usr/bin/google-chrome",
  "/usr/bin/chromium-browser",
  "/usr/bin/chromium",
].filter(Boolean);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export async function launch(port = 9400 + Math.floor(Math.random() * 400)) {
  let chrome = null;
  for (const bin of CHROME_PATHS) {
    chrome = spawn(bin, [
      "--headless=new", "--disable-gpu", "--no-sandbox", "--disable-dev-shm-usage",
      `--remote-debugging-port=${port}`, "about:blank",
    ], { stdio: "ignore" });
    const ok = await new Promise((r) => { chrome.once("error", () => r(false)); setTimeout(() => r(true), 400); });
    if (ok) break;
    chrome = null;
  }
  if (!chrome) throw new Error("Chrome tidak ditemukan; setel CHROME_PATH");

  let target = null;
  for (let i = 0; i < 60 && !target; i++) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      target = list.find((t) => t.type === "page");
    } catch { /* belum siap */ }
    if (!target) await sleep(250);
  }
  if (!target) throw new Error("Chrome tidak merespons");

  const ws = await new Promise((res, rej) => {
    const socket = new WebSocket(target.webSocketDebuggerUrl);
    socket.onopen = () => res(socket);
    socket.onerror = rej;
  });

  let id = 1;
  const konsol = [];
  const send = (method, params = {}) => {
    const seq = id++;
    return Promise.race([
      new Promise((res, rej) => {
        const on = (e) => {
          const msg = JSON.parse(e.data);
          if (msg.id !== seq) return;
          ws.removeEventListener("message", on);
          msg.error ? rej(new Error(`${method}: ${msg.error.message}`)) : res(msg.result);
        };
        ws.addEventListener("message", on);
        ws.send(JSON.stringify({ id: seq, method, params }));
      }),
      new Promise((_, rej) => setTimeout(() => rej(new Error(`${method}: waktu habis`)), 15000)),
    ]);
  };

  ws.addEventListener("message", (e) => {
    const msg = JSON.parse(e.data);
    if (msg.method === "Runtime.consoleAPICalled" && ["error", "warning"].includes(msg.params.type)) {
      konsol.push({ tipe: msg.params.type, teks: (msg.params.args || []).map((a) => a.value ?? a.description).join(" ") });
    }
    if (msg.method === "Runtime.exceptionThrown") {
      konsol.push({ tipe: "exception", teks: msg.params.exceptionDetails.text });
    }
  });

  await send("Page.enable");
  await send("Runtime.enable");

  const page = {
    konsol,
    async goto(url) {
      konsol.length = 0;
      await send("Page.navigate", { url });
      await this.waitFor("document.readyState === 'complete'", 8000);
      await sleep(260);
    },
    async eval(expression) {
      const out = await send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
      if (out.exceptionDetails) throw new Error(out.exceptionDetails.text);
      return out.result.value;
    },
    async waitFor(expression, ms = 4000) {
      const batas = Date.now() + ms;
      while (Date.now() < batas) {
        if (await this.eval(`Boolean(${expression})`).catch(() => false)) return true;
        await sleep(90);
      }
      throw new Error(`kondisi tidak pernah tercapai: ${expression}`);
    },
    click(selector) {
      return this.eval(`(()=>{const el=document.querySelector(${JSON.stringify(selector)});
        if(!el) throw new Error("tidak ada elemen: "+${JSON.stringify(selector)});
        el.click(); return true;})()`);
    },
    fill(selector, value) {
      return this.eval(`(()=>{const el=document.querySelector(${JSON.stringify(selector)});
        if(!el) throw new Error("tidak ada elemen: "+${JSON.stringify(selector)});
        const proto=el instanceof HTMLTextAreaElement?HTMLTextAreaElement:
          el instanceof HTMLSelectElement?HTMLSelectElement:HTMLInputElement;
        Object.getOwnPropertyDescriptor(proto.prototype,"value").set.call(el, ${JSON.stringify(value)});
        el.dispatchEvent(new Event("input",{bubbles:true}));
        el.dispatchEvent(new Event("change",{bubbles:true}));
        return el.value;})()`);
    },
    key(key) {
      return this.eval(`document.dispatchEvent(new KeyboardEvent("keydown",{key:${JSON.stringify(key)},bubbles:true}))`);
    },
    text(selector) {
      return this.eval(`(document.querySelector(${JSON.stringify(selector)})||{}).textContent?.trim() ?? null`);
    },
    count(selector) {
      return this.eval(`document.querySelectorAll(${JSON.stringify(selector)}).length`);
    },
    visible(selector) {
      return this.eval(`(()=>{const el=document.querySelector(${JSON.stringify(selector)});
        if(!el) return false; const cs=getComputedStyle(el);
        return cs.display!=="none" && cs.visibility!=="hidden" && el.getClientRects().length>0;})()`);
    },
    close() { ws.close(); chrome.kill(); },
  };

  return page;
}
