-- screens/court_list.lua —— 臣僚：朝臣名录、忠诚才具、任免与开科
-- 数据形状（gs）：court = { { name, dept, loyalty, skill, title }, … }
local U = require("ui")
local S = {}

local HINT = "▲▼ 选人　OK 查看　左右 页签"
local PER = 5
local SY, RY = 78, 100

local function court_of(gs)
  local c = gs.court
  if type(c) == "table" and #c > 0 then return c end
  return {}
end

function S.draw(ctx, g, V)
  local gs = V.gs or {}
  local hits = U.page(ctx, g, V, { tab = "court_list", hint = HINT })
  local rows = court_of(gs)
  local n = #rows
  local x, w = 256, 524
  local sel = tonumber(V.cursor) or tonumber(V.index) or 1
  if sel < 1 then sel = 1 end
  if n > 0 and sel > n then sel = n end

  U.section(g, x, SY, w, "朝臣")
  U.text(g, x + w, SY, "在册 " .. tostring(n) .. " 人", { size = "small", align = "right" })

  if n == 0 then
    U.empty(g, x, RY, w, 140, "朝中无臣，百事待举。可开科取士。")
  else
    local first = ((sel - 1) // PER) * PER + 1
    local last = math.min(first + PER - 1, n)
    for i = first, last do
      local c = rows[i] or {}
      local ry = RY + (i - first) * U.ROWH
      U.row(g, x, ry, w, 26, {
        { s = tostring(c.name or "—"), w = 112 },
        { s = tostring(c.dept or "—"), w = 96 },
        { s = "忠 " .. tostring(c.loyalty or 0), w = 84 },
        { s = "才 " .. tostring(c.skill or 0), w = 84 },
        { s = tostring(c.title or (c.chief and "主官" or "属官")), w = 60, align = "right" },
      }, { selected = (i == sel) })
      U.rowhit(hits, x, ry, w, 26, "select", i)
    end
  end

  -- 详情
  local c = rows[sel] or {}
  local by, bh = 252, 92
  U.rect(g, x, by, w, bh)
  U.text(g, x + 12, by + 26, tostring(c.name or "—"),
    { size = "medium", valign = "middle", maxw = 220 })
  U.text(g, x + w - 12, by + 26,
    tostring(c.dept or "") .. (c.title and (" · " .. tostring(c.title)) or ""),
    { size = "small", align = "right", valign = "middle" })
  U.hline(g, x + 8, by + 36, w - 16)
  U.body(g, x + 12, by + 46, w - 24, 38,
    tostring(c.note or c.desc or
      ("忠诚 " .. tostring(c.loyalty or 0) .. " · 才具 " .. tostring(c.skill or 0) ..
        "。差遣未定，可任可罢。")),
    { size = "small" })

  -- 任免
  local btns = {
    { label = "任命", arg = "appoint" },
    { label = "罢免", arg = "dismiss" },
    { label = "赏赐", arg = "reward" },
    { label = "查办", arg = "impeach" },
  }
  local bw, gap = 124, 8
  local ok = (n > 0)
  for i = 1, #btns do
    local bx = x + (i - 1) * (bw + gap)
    U.button(g, bx, 358, bw, 32, btns[i].label, { disabled = not ok })
    if ok then U.rowhit(hits, bx, 358, bw, 32, "action", btns[i].arg) end
  end
  U.button(g, x, 398, 180, 32, "开科取士", {})
  U.rowhit(hits, x, 398, 180, 32, "ok", "keju")
  U.text(g, x + w, 414, "科举三年一次，亦可恩科。",
    { size = "small", align = "right", valign = "middle", maxw = 300 })
  return hits
end

return S
