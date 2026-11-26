// tools/poke.mjs —— 直接打 /key、/touch，打印 HTTP 状态与响应体
const BASE = process.env.PREVIEW_BASE || "http://127.0.0.1:41994";
const [kind, ...rest] = process.argv.slice(2);
const body = kind === "key" ? { key: rest[0] || "ok" } : { x: Number(rest[0]) || 0, y: Number(rest[1]) || 0, gesture: rest[2] || "tap" };
const r = await fetch(`${BASE}/${kind}`, {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify(body),
});
const text = await r.text();
console.log("status", r.status, "body", text.slice(0, 400));
await new Promise((res) => setTimeout(res, 350));
const s = await (await fetch(`${BASE}/status`)).json();
console.log("logs", JSON.stringify((s.logs || []).slice(-8)), "fault", s.fault);
