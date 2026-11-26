-- screens/war.lua —— 军国：边患、胜算、征伐/和亲/戍边
-- 数据形状（gs）：war_targets = { { name, enemy, relation, chance, note }, … }
local U = require("ui")
local S = {}

local HINT = "▲▼ 选边患　OK 查看　左右 页签"
local NAMES = { "北狄", "南蛮", "西羌" }
local PER = 3
local SY, RY, RH = 78, 100, 32

local function targets_of(gs)
  local t = gs.war_targets or gs.war or gs.targets
  if type(t) == "table" and #t > 0 then return t end
  local out = {}
  for i = 1, #NAMES do out[i] = { name = NAMES[i] } end
  return out
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = "war", hint = HINT, right = "军国" })
  local x, w = 256, 524
  local rows = targets_of(gs)
  local n = #rows
  local sel = tonumber(V.cursor) or tonumber(V.index) or 1
  if sel < 1 then sel = 1 end
  if n > 0 and sel > n then sel = n end

  U.section(g, x, SY, w, "边患")

  for i = 1, math.min(PER, math.max(n, 1)) do
    local t = rows[i] or {}
    local ry = RY + (i - 1) * RH
    local is_sel = (i == sel)
    local chance = tonumber(t.chance)
    U.row(g, x, ry, w, 28, {
      { s = tostring(t.name or NAMES[i] or "—"), w = 96 },
      { s = "敌众 " .. tostring(t.enemy or "—"), w = 96 },
      { s = chance and (tostring(chance) .. "%") or "未探", w = 52 },
      { s = tostring(t.relation or "—"), w = 60, align = "right" },
    }, { selected = is_sel })
    U.rowhit(hits, x, ry, w, 28, "select", i)
  end

  -- 详情
  local t = rows[sel] or {}
  local by, bh = 202, 130
  U.rect(g, x, by, w, bh)
  U.text(g, x + 12, by + 24, tostring(t.name or "—") .. "　" ..
    tostring(t.relation or ""), { size = "medium", valign = "middle", maxw = 300 })
  U.text(g, x + w - 12, by + 24,
    t.chance and ("胜算 " .. tostring(t.chance) .. "%") or "胜算未探",
    { size = "small", align = "right", valign = "middle" })
  U.hline(g, x + 8, by + 34, w - 16)
  U.body(g, x + 12, by + 42, w - 24, 46,
    tostring(t.note or t.desc or "边关消息未至，敌情不明。可遣斥候探之。"),
    { size = "small" })

  local st, res = gs.stats or {}, gs.res or {}
  U.text(g, x + 12, by + 100,
    "兵力 " .. tostring(res.troops or 0) .. " 万　粮草 " .. tostring(res.grain or 0) ..
    " 万石　军心 " .. tostring(st.jun or 0),
    { size = "small", maxw = w - 24 })
  U.text(g, x + 12, by + 118,
    "库银 " .. tostring(res.gold or 0) .. " 万贯　民心 " .. tostring(st.min or 0) ..
    "　健康 " .. tostring(gs.health or 0),
    { size = "small", maxw = w - 24 })

  local bw, gap = 168, 10
  local btns = {
    { label = "征伐", arg = "war" },
    { label = "和亲", arg = "peace" },
    { label = "戍边", arg = "fortify" },
  }
  for i = 1, #btns do
    local bx = x + (i - 1) * (bw + gap)
    U.button(g, bx, 344, bw, 34, btns[i].label, {})
    U.rowhit(hits, bx, 344, bw, 34, "ok", btns[i].arg)
  end
  U.text(g, x, 396, "战端一开，非胜即负；和亲有岁币，戍边耗粮草。",
    { size = "small", maxw = w })
  return hits
end

return S
