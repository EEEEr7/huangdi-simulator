-- screens/harem.lua —— 后宫：妃嫔列表、子嗣、选秀/临幸/立储
-- 数据形状（gs）：harem = { { name, favor, son, wife }, … }
--               heirs = { { name, age, intel, mother, crown }, … }
local U = require("ui")
local S = {}

local HINT = "▲▼ 选择　OK 查看　左右 页签"
local MAX_ROW = 5
local SY, RY, RH = 78, 100, 28   -- 标题 / 首行 / 行距

local function safe(t)
  return type(t) == "table" and t or {}
end

local function draw_consorts(g, hits, rows, count, sel, x, w)
  if #rows == 0 then
    U.empty(g, x, RY, w, 26 * count, count > 0 and "后宫虚位，尚待选秀。" or "（无）")
    return
  end
  for i = 1, math.min(count, #rows) do
    local r = rows[i] or {}
    local ry = RY + (i - 1) * RH
    U.row(g, x, ry, w, 26, {
      { s = tostring(r.name or "—"), w = 130 },
      { s = tostring(r.title or (r.wife and "皇后" or "妃嫔")), w = 76 },
      { s = "恩宠", w = 46 },
      { s = string.rep("●", math.max(0, math.min(5, math.floor((tonumber(r.favor) or 0) / 20)))), w = 92 },
      { s = "皇子 " .. tostring(r.son or 0), w = 92, align = "right" },
    }, { selected = (i == sel) })
    U.rowhit(hits, x, ry, w, 26, "select", i)
  end
end

local function draw_heirs(g, V, hits, heirs, x, w)
  U.section(g, x, 252, w, "子嗣")
  if #heirs == 0 then
    U.empty(g, x, 270, w, 64, "尚无子嗣。临幸后宫，或可绵延国祚。")
    return
  end
  for i = 1, math.min(3, #heirs) do
    local h = heirs[i] or {}
    U.text(g, x, 274 + (i - 1) * 22,
      tostring(h.name or "—") .. "　" .. tostring(h.age or 0) .. " 岁　生母 " ..
      tostring(h.mother or "—") .. "　才具 " .. tostring(h.intel or 0) ..
      (h.crown and "　【储君】" or ""),
      { size = "small", maxw = w - 160 })
  end
  if #heirs > 3 then
    U.text(g, x + w, 274 + 2 * 22, "… 另有 " .. tostring(#heirs - 3) .. " 人",
      { size = "small", align = "right" })
  end
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = "harem", hint = HINT })
  local x, w = 256, 524
  local picking = (V.sub == "pick")
  local rows = picking and safe(V.candidates or gs.candidates) or safe(gs.harem)
  local sel = tonumber(V.cursor) or tonumber(V.index) or 1
  if sel < 1 then sel = 1 end
  if #rows > 0 and sel > #rows then sel = #rows end

  U.section(g, x, SY, w, picking and "待选秀女" or "六宫")
  draw_consorts(g, hits, rows, MAX_ROW, sel, x, w)

  local heirs = safe(gs.heirs)
  if picking then
    local cur = rows[sel] or {}
    U.section(g, x, 252, w, "家世")
    U.body(g, x, 270, w, 60,
      tostring(cur.desc or cur.family or "礼部呈册，尚未详录家世。"),
      { size = "small" })
  else
    draw_heirs(g, V, hits, heirs, x, w)
  end

  local bw, gap = 168, 10
  local bx = x
  local btns = {
    { label = picking and "选定" or "选秀", cmd = "ok", arg = picking and "pick_done" or "pick",
      selected = picking },
    { label = "临幸", cmd = "ok", arg = "visit", disabled = #rows == 0 },
    { label = "立储", cmd = "action", arg = "crown", disabled = #heirs == 0 },
  }
  for i = 1, #btns do
    local b = btns[i]
    local by = 348
    U.button(g, bx, by, bw, 34, b.label, { selected = b.selected, disabled = b.disabled })
    if not b.disabled then U.rowhit(hits, bx, by, bw, 34, b.cmd, b.arg) end
    bx = bx + bw + gap
  end
  U.text(g, x, 404, picking and "选秀一次，后宫添一人。" or "恩宠、子嗣、储位，皆在人心。",
    { size = "small", valign = "middle", maxw = 360 })
  return hits
end

return S
