-- screens/ending.lua —— 结局：大画、评价徽记、本纪、谥议、重新开始
-- 数据形状（gs）：ended = { id, text, grade }；也可用 V.ending 覆盖
local U = require("ui")
local S = {}

local HINT = "OK 重新开始　BACK 回标题"
local LABEL = {
  victory = "中兴", collapse = "亡国", death = "寿终",
  abdicate = "禅位", rebel = "民变", defeat = "兵败",
}
local VERDICT = {
  victory = "海内复定，四夷来朝。史官落笔：中兴之主。",
  collapse = "府库空，城郭破。史官落笔：国祚至此而终。",
  death = "药石无灵，龙驭上宾。史官落笔：在位若干年，寿终正寝。",
  abdicate = "倦于万机，退居别宫。史官落笔：禅位而去。",
  rebel = "烽火起于州郡，宫门夜开。史官落笔：失其鹿。",
  defeat = "王师败绩，社稷倾危。史官落笔：兵败如山倒。",
}

local function ending_of(V)
  local e = V.ending or (V.gs and V.gs.ended) or {}
  if type(e) ~= "table" then e = { text = tostring(e) } end
  return e
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local e = ending_of(V)
  local hits = U.page(ctx, g, V, {
    header = true, sidebar = false, tabs = false, hint = HINT, right = "结局",
  })

  local id = tostring(e.id or "death")
  local grade = tostring(e.grade or LABEL[id] or "盖棺")
  local text = tostring(e.text or VERDICT[id] or "青史一页，墨迹未干。")

  -- 大画
  U.gray(ctx, g, V, "e_end", 32, 56, 384, 240)
  U.text(g, 32, 306, "在位 " .. tostring(gs.year or 1) .. " 年 · 春秋 " ..
    tostring(gs.age or 16) .. " 岁 · 年号 " .. tostring(gs.era or "承平"),
    { size = "small", maxw = 384 })

  -- 评价徽记
  U.chip(g, 32, 330, "结局 · " .. grade, { inverse = true, h = 28, size = "medium" })
  U.body(g, 32, 368, 384, 56, text, { size = "small" })

  -- 本纪
  local x, w = 440, 336
  U.section(g, x, 56, w, "本纪")
  local log = type(gs.log) == "table" and gs.log or {}
  local first = math.max(1, #log - 7)
  local shown = 0
  for i = first, #log do
    local s = tostring(log[i])
    U.text(g, x, 76 + shown * 24, "· " .. s, { size = "small", maxw = w })
    shown = shown + 1
    if shown >= 8 then break end
  end
  if shown == 0 then
    U.text(g, x, 76, "· 本纪未成，唯余一纸空白。", { size = "small" })
  end

  U.section(g, x, 282, w, "谥议")
  U.body(g, x, 300, w, 64,
    tostring(e.eulogy or "盖棺论定，付与后人。国之兴衰，非一人之力。"),
    { size = "small" })
  U.text(g, x, 372, "国势 " .. tostring((gs.stats or {}).wang or 0) ..
    " · 民心 " .. tostring((gs.stats or {}).min or 0) ..
    " · 健康 " .. tostring(gs.health or 0), { size = "small", maxw = w })

  U.button(g, x, 396, w, 36, "重新开始", { selected = true })
  U.rowhit(hits, x, 396, w, 36, "ok", "restart")
  return hits
end

return S
