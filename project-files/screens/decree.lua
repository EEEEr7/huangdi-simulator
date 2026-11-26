-- screens/decree.lua —— 诏令：十六道常诏，一页五行，右侧详情
-- 数据形状（gs）：decrees = { { name, hint, tag, done }, … }
-- 未提供时按常诏名单列出（不可执行，tag 留空）
local U = require("ui")
local S = {}

local HINT = "▲▼ 选诏　OK 颁诏　左右 页签"
local NAMES = {
  "开科", "征兵", "赈灾", "修河", "巡狩", "大赦", "赏军", "查贪",
  "封禅", "兴学", "屯田", "铸钱", "市易", "禁奢", "练兵", "和籴",
}
local PER = 5

local function list_of(gs)
  local ok = type(gs.decrees) == "table" and gs.decrees
  if ok and #ok > 0 then return ok end
  local out = {}
  for i = 1, #NAMES do out[i] = { name = NAMES[i] } end
  return out
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = "decree", hint = HINT })
  local items = list_of(gs)
  local n = #items
  local sel = tonumber(V.index) or tonumber(V.cursor) or 1
  if sel < 1 then sel = 1 end
  if n > 0 and sel > n then sel = n end

  local x, w = 256, 524
  local first = ((sel - 1) // PER) * PER + 1
  local last = math.min(first + PER - 1, n)
  for i = first, last do
    local it = items[i] or {}
    local d = NAMES[i] or ""
    local s = tostring(it.name or d)
    local done = it.done == true
    U.row(g, x, U.ROWY + (i - first) * U.ROWH, w, 26, {
      { s = tostring(i), w = 26, align = "right" },
      { s = s, w = 114 },
      { s = tostring(it.hint or ""), w = 296 },
      { s = done and "已行" or tostring(it.tag or ""), w = 50, align = "right" },
    }, { selected = (i == sel), disabled = done })
    U.rowhit(hits, x, U.ROWY + (i - first) * U.ROWH, w, 26, "select", i)
  end

  -- 下方详情
  local it = items[sel] or {}
  local bx, by, bw, bh = x, 226, w, 150
  U.rect(g, bx, by, bw, bh)
  U.text(g, bx + 12, by + 26, tostring(it.name or NAMES[sel] or "—"),
    { size = "medium", valign = "middle", maxw = 300 })
  U.text(g, bx + bw - 12, by + 26, tostring(it.tag or ""),
    { size = "small", align = "right", valign = "middle" })
  U.hline(g, bx + 8, by + 36, bw - 16)
  U.body(g, bx + 12, by + 48, bw - 24, 44,
    tostring(it.hint or "此诏内容待定，尚未载入本纪。"), { size = "small" })
  U.text(g, bx + 12, by + 112,
    "常诏十六道 · 每页五行 · 第 " .. tostring((sel - 1) // PER + 1) ..
    " / " .. tostring(math.max(1, (n + PER - 1) // PER)) .. " 页",
    { size = "small" })
  U.text(g, bx + 12, by + 132, "红笔一下，便成定局。", { size = "small" })

  local disabled = (n == 0) or (it.done == true)
  U.button(g, x + bw - 160, 390, 160, 36, "颁诏", { selected = V.cursor == "decree" or V.sub == "issue", disabled = disabled })
  if not disabled then U.rowhit(hits, x + bw - 160, 390, 160, 36, "ok", "decree") end
  U.text(g, x, 408, "每月限颁一道，逾月作废。", { size = "small", valign = "middle", maxw = 340 })
  return hits
end

return S
