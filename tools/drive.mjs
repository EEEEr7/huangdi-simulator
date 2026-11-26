// tools/drive.mjs —— 本地预览驱动：node tools/drive.mjs [status|key <k>|tap <x> <y>|shot <name>|restart|wait <ms>]...
// 预览服务默认 http://127.0.0.1:41994
import { writeFileSync, mkdirSync } from "node:fs";

const BASE = process.env.PREVIEW_BASE || "http://127.0.0.1:41994";
const args = process.argv.slice(2);
const outDir = ".tmp";
mkdirSync(outDir, { recursive: true });

async function jget(p) {
  const r = await fetch(BASE + p);
  return r.json();
}
async function jpost(p, body) {
  const r = await fetch(BASE + p, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body || {}),
  });
  return r.json().catch(() => ({}));
}
function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

let i = 0;
while (i < args.length) {
  const a = args[i++];
  if (a === "status") {
    const s = await jget("/status");
    console.log(JSON.stringify({ w: s.width, h: s.height, rev: s.revision, fault: s.fault, logs: (s.logs || []).slice(-6) }));
  } else if (a === "key") {
    const k = args[i++];
    const r = await jpost("/key", { key: k });
    if (r && r.error) console.log("key error:", JSON.stringify(r));
    await sleep(120);
  } else if (a === "tap") {
    const x = Number(args[i++]), y = Number(args[i++]);
    await jpost("/touch", { x, y, gesture: "tap" });
    await sleep(150);
  } else if (a === "shot") {
    const name = args[i++] || "frame";
    const r = await fetch(BASE + "/frame.png");
    const b = Buffer.from(await r.arrayBuffer());
    const p = `${outDir}/${name}.png`;
    writeFileSync(p, b);
    console.log("shot", p, b.length);
  } else if (a === "restart") {
    await jpost("/restart", {});
    await sleep(900);
    console.log("restarted");
  } else if (a === "wait") {
    await sleep(Number(args[i++]) || 300);
  } else {
    console.log("unknown cmd", a);
  }
}
