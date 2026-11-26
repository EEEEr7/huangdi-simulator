-- screens/court.lua —— 朝会：本月折子、选项、批红结果
-- 数据形状（gs）：
--   pending / queue[1] = 事件表 { title, text, tag, choices = { { label, hint }, … } }
--   pending.result（或 outcome）= 批红结果文字，存在时改为弹窗
local U = require("ui")
local S = {}

local HINT = "▲▼ 选择　OK 批阅　左右 页签"
local EMPTY = "本月无急奏。可下诏施政，或去后宫、军国走一遭。"
local NUM = { "一", "二", "三", "四", "五" }

-- 事件 tag → 场景图（缺图自动降级为「？」框）
local SCENE = {
  ["天灾"] = "s_flood", ["人祸"] = "s_famine", ["后宫"] = "s_harem",
  ["朝争"] = "s_court", ["奇案"] = "s_mystery", ["边患"] = "s_war",
  ["祥瑞"] = "s_omen", ["变法"] = "s_reform",
}

local function event_of(gs)
  local p = gs.pending
  if type(p) == "table" then
    if type(p.event) == "table" then return p.event end
    return p
  end
  local q = gs.queue
  if type(q) == "table" and type(q[1]) == "table" then
    if type(q[1].event) == "table" then return q[1].event end
    return q[1]
  end
  return nil
end

local function result_of(gs)
  local p = gs.pending
  if type(p) ~= "table" then return nil end
  local r = p.result or p.outcome
  if type(r) == "string" and r ~= "" then return r end
  if type(r) == "table" then
    local t = r.text or r.desc or r.body
    if type(t) == "string" and t ~= "" then return t end
  end
  return nil
end

local function queue_len(gs)
  local q = gs.queue
  if type(q) == "table" then return #q end
  return 0
end

-- 批红弹窗：遮住折子，只留一条「继续」
local function draw_result(g, V, gs, hits)
  local p = gs.pending or {}
  local dh = U.dialog(g, {
    title = U.t(V, "court_result_title", "批红"),
    tag = tostring(p.tag or ""),
    text = result_of(gs) or "",
    x = 244, w = 524, h = 250,
    choices = { { label = "继续", cmd = "ok", arg = "continue" } },
  })
  for i = 1, #dh do hits[#hits + 1] = dh[i] end
end

local function draw_near(g, V, gs, x, w, y)
  if y + 80 > 440 then return end
  U.section(g, x, y, w, "近事")
  local log = type(gs.log) == "table" and gs.log or {}
  local room = math.floor((436 - (y + 18)) / 20)
  local n = math.min(3, room)
  local shown = 0
  for i = #log, math.max(1, #log - n + 1), -1 do
    local s = tostring(log[i])
    U.text(g, x, y + 18 + shown * 20, s, { size = "small", maxw = w })
    shown = shown + 1
    if shown >= n then break end
  end
  if shown == 0 then U.text(g, x, y + 18, "（本纪未记）", { size = "small" }) end
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = "court", hint = HINT })

  if result_of(gs) then
    draw_result(g, V, gs, hits)
    return hits
  end

  local x, y, w = 256, U.ROWY, 524
  local ev = event_of(gs)
  local qn = queue_len(gs)

  if not ev then
    U.card(g, x, y, w, 120, U.t(V, "court_empty_title", "本月无事"), "守成")
    U.body(g, x + 12, y + 38, w - 24, 66, U.t(V, "court_empty", EMPTY),
      { size = "medium", lines = 2 })
    U.button(g, x, y + 136, w, 34, "静候下月", { selected = true })
    U.rowhit(hits, x, y + 136, w, 34, "ok", "next_month")
    draw_near(g, V, gs, x, w, y + 190)
    return hits
  end

  local choices = type(ev.choices) == "table" and ev.choices or {}
  if #choices > 5 then
    local keep = {}
    for i = 1, 5 do keep[i] = choices[i] end
    choices = keep
  end
  local cur = tonumber(V.cursor) or 1
  if cur < 1 then cur = 1 end
  if #choices > 0 and cur > #choices then cur = #choices end

  local card_h = 128 + #choices * 28
  U.card(g, x, y, w, card_h, tostring(ev.title or "奏折"), tostring(ev.tag or ""))
  local body = tostring(ev.text or ev.body or ev.desc or "")
  local skey = SCENE[tostring(ev.tag or "")]
  local has_scene = false
  if skey and V.A and V.A.has then has_scene = V.A.has(ctx, skey) end
  local tw = w - 24
  if has_scene then
    U.scene(ctx, g, V, skey, x + w - 148, y + 36, 136, 76)
    tw = w - 168
  end
  U.body(g, x + 12, y + 36, tw, 66, body, { size = "medium" })
  U.hline(g, x + 8, y + 116, w - 16)

  for i = 1, #choices do
    local c = choices[i] or {}
    local ry = y + 124 + (i - 1) * 28
    local label = (NUM[i] or tostring(i)) .. "、" .. tostring(c.label or "—")
    U.row(g, x + 8, ry, w - 16, 26, {
      { s = label, w = 344 },
      { s = tostring(c.hint or c.cost or ""), w = 148, align = "right" },
    }, { selected = (cur == i) })
    U.rowhit(hits, x + 8, ry, w - 16, 26, "select", i)
  end

  local ly = y + card_h + 14
  draw_near(g, V, gs, x, w, ly)

  local right = "朝会"
  if qn > 1 then right = "折 1 / " .. tostring(qn) end
  U.footer(g, U.hint(V, HINT), right)
  return hits
end

return S
