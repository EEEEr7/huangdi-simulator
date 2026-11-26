-- screens/summary.lua —— 月末结算：六维与国用的增减、本纪最后一笔、进入下月
-- 数据形状（gs）：month_effects 可为 { wang = 2, gold = -3, … }、
--               { stats = {…}, res = {…} } 或 { { key, delta }, … }
local U = require("ui")
local S = {}

local HINT = "OK 进入下月　左右 页签"

local function map_of(eff)
  local m = {}
  if type(eff) ~= "table" then return m end
  for k, v in pairs(eff) do
    if type(v) == "number" then m[k] = v end
  end
  local st, res = eff.stats, eff.res
  if type(st) == "table" then
    for k, v in pairs(st) do if type(v) == "number" then m[k] = v end end
  end
  if type(res) == "table" then
    for k, v in pairs(res) do if type(v) == "number" then m[k] = v end end
  end
  for _, e in ipairs(eff) do
    if type(e) == "table" and type(e.key) == "string" and type(e.delta) == "number" then
      m[e.key] = e.delta
    end
  end
  return m
end

local function dtext(d)
  if type(d) ~= "number" or d == 0 then return "—" end
  if d > 0 then return "▲ " .. tostring(d) end
  return "▼ " .. tostring(-d)
end

-- 一行：标签 / 增减 / 现值（右侧对齐，避免长数字压字）
local function line(g, x, w, y, label, d, v)
  U.text(g, x, y, label, { size = "small", maxw = 56 })
  U.text(g, x + 62, y, dtext(d), { size = "small", maxw = 80 })
  U.text(g, x + w, y, tostring(tonumber(v) or 0), { size = "small", align = "right", maxw = 78 })
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = gs.phase, header = true, hint = HINT, right = "月末" })
  local x, w = 256, 524
  local st = gs.stats or {}
  local res = gs.res or {}
  local dm = map_of(gs.month_effects)

  U.text(g, x, 56, tostring(gs.era or "承平") .. " " .. tostring(gs.year or 1) ..
    " 年 · " .. (U.MONTHS[tonumber(gs.month) or 1] or "正月"),
    { size = "medium", maxw = 300 })
  U.text(g, x + w, 56, "月末结算", { size = "small", align = "right" })

  -- 左半：六维 + 健康
  U.section(g, x, 82, 248, "六维")
  local cy = 116
  for i = 1, #U.STATS do
    local s = U.STATS[i]
    line(g, x, 248, cy + (i - 1) * 26, s.label, dm[s.key], st[s.key])
  end
  line(g, x, 248, cy + #U.STATS * 26, "健康", dm.health, gs.health)

  -- 右半：国用
  U.section(g, x + 264, 82, 260, "国用")
  for i = 1, #U.RES do
    local r = U.RES[i]
    line(g, x + 264, 260, cy + (i - 1) * 26, r.label, dm[r.key], res[r.key])
  end

  local log = type(gs.log) == "table" and gs.log or {}
  local note = (log[#log] ~= nil) and tostring(log[#log]) or "本月无事可记。"
  U.section(g, x, 320, w, "本纪")
  U.body(g, x, 338, w, 44, note, { size = "small" })

  U.button(g, x, 400, w, 36, "进入下月", { selected = true })
  U.rowhit(hits, x, 400, w, 36, "ok", "next_month")
  return hits
end

return S
