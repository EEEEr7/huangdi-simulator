-- ui.lua —— 界面绘制原语（只画，不做游戏规则）
-- 屏幕用法：
--   local U = require("ui")
--   local hits = U.page(ctx, g, V, { tab = "court", hint = "…" })
--   …
--   return hits
-- 描边固定 2px；只用色 0（纸）与 15（墨），不画中间灰。
-- 坐标：顶栏 0..40，左栏 8..236，右栏 244..792，底栏 448..480。

local U = {}

U.W, U.H = 800, 480
U.TOP, U.BOT, U.LW = 40, 32, 2
U.LEFT, U.CX, U.CW = 236, 244, 548
U.ROWY, U.ROWH = 82, 28
U.INK, U.PAPER = 15, 0

U.STATS = {
  { key = "wang", label = "国势" },
  { key = "min",  label = "民心" },
  { key = "jun",  label = "军心" },
  { key = "wei",  label = "威望" },
  { key = "cai",  label = "才略" },
  { key = "de",   label = "德行" },
}

U.RES = {
  { key = "gold",   label = "税银", unit = "万贯" },
  { key = "grain",  label = "粮草", unit = "万石" },
  { key = "troops", label = "兵力", unit = "万" },
}

U.MONTHS = { "正月", "二月", "三月", "四月", "五月", "六月",
             "七月", "八月", "九月", "十月", "冬月", "腊月" }
U.DIFFS = { "宽仁", "中庸", "严苛" }
U.TABS = {
  { key = "court",      label = "朝会" },
  { key = "decree",     label = "诏令" },
  { key = "harem",      label = "后宫" },
  { key = "court_list", label = "臣僚" },
  { key = "war",        label = "军国" },
}

-- ── 基础 ──────────────────────────────────────────────────────────
function U.init(ctx)
  U.ctx = ctx
  U.f = ctx and ctx.fonts or nil
  return U.f
end

function U.font(name)
  name = name or "medium"
  local f = U.f
  if not f and U.ctx and U.ctx.fonts then f = U.ctx.fonts end
  if not f then return nil end
  return f[name]
end

function U.measure(font, s)
  s = (s == nil) and "" or tostring(s)
  if font and font.measure then return font:measure(s) end
  return #s * 8
end

local function chars(s)
  local t = {}
  if utf8 and utf8.codes then
    for _, cp in utf8.codes(s) do t[#t + 1] = utf8.char(cp) end
  else
    for i = 1, #s do t[#t + 1] = s:sub(i, i) end
  end
  return t
end
U.chars = chars

-- 单行截断：超出 maxw 用「…」收尾
function U.fit(font, s, maxw)
  s = (s == nil) and "" or tostring(s)
  if not maxw or maxw <= 0 then return "" end
  if U.measure(font, s) <= maxw then return s end
  local cs, out = chars(s), ""
  for i = 1, #cs do
    local nxt = out .. cs[i]
    if U.measure(font, nxt .. "…") > maxw then break end
    out = nxt
  end
  return out .. "…"
end

-- 折行：按字断行（中文不依赖空格）
function U.wrap(font, s, w, maxlines)
  local out, line = {}, ""
  local limit = maxlines or 99
  local cs = chars((s == nil) and "" or tostring(s))
  for i = 1, #cs do
    local c = cs[i]
    if c == "\n" then
      out[#out + 1] = line
      line = ""
      if #out >= limit then return out end
    else
      local nxt = line .. c
      if line ~= "" and U.measure(font, nxt) > w then
        out[#out + 1] = line
        if #out >= limit then return out end
        line = (c == " ") and "" or c
      else
        line = nxt
      end
    end
  end
  if line ~= "" or #out == 0 then out[#out + 1] = line end
  return out
end

-- 文本：默认左上锚点，可选 size/font/color/align/valign/maxw
function U.text(g, x, y, s, o)
  o = o or {}
  local f = o.font or U.font(o.size)
  local t = (s == nil) and "" or tostring(s)
  if o.maxw then t = U.fit(f, t, o.maxw) end
  local opt = { font = f, color = o.color or U.INK }
  if o.align then opt.align = o.align end
  if o.valign then opt.valign = o.valign end
  g:text(x, y, t, opt)
  return t
end

-- 多行正文：交给 text_box 裁剪，保证不出框
function U.body(g, x, y, w, h, s, o)
  o = o or {}
  local f = o.font or U.font(o.size or "medium")
  local opt = { font = f, color = o.color or U.INK,
                wrap = o.wrap or "char", overflow = o.overflow or "clip" }
  if o.line_gap then opt.line_gap = o.line_gap end
  g:text_box(x, y, w, h, (s == nil) and "" or tostring(s), opt)
end

-- ── 线与块 ────────────────────────────────────────────────────────
function U.fill(g, x, y, w, h, color)
  if w and h and w > 0 and h > 0 then
    g:rect(x, y, w, h, { fill = true, color = color or U.INK })
  end
end

function U.paper(g, x, y, w, h)
  U.fill(g, x, y, w, h, U.PAPER)
end

function U.rect(g, x, y, w, h, color)
  if w and h and w > 0 and h > 0 then
    g:rect(x, y, w, h, { line_width = U.LW, color = color or U.INK })
  end
end

function U.hline(g, x, y, w, color)
  U.fill(g, x, y, w, 2, color)
end

function U.vline(g, x, y, h, color)
  U.fill(g, x, y, 2, h, color)
end

-- 禁用态点线框：2×2 墨点，6px 间距（不依赖 pattern 能力）
function U.dotted(g, x, y, w, h, color)
  local step = 6
  if w < 4 or h < 4 then return end
  local i = 0
  while x + i * step <= x + w - 2 do
    U.fill(g, x + i * step, y, 2, 2, color)
    U.fill(g, x + i * step, y + h - 2, 2, 2, color)
    i = i + 1
  end
  i = 1
  while y + i * step <= y + h - 4 do
    U.fill(g, x, y + i * step, 2, 2, color)
    U.fill(g, x + w - 2, y + i * step, 2, 2, color)
    i = i + 1
  end
end

-- 六维/胜算横条：外框 2px + 内部实心
function U.bar(g, x, y, w, h, v, maxv, color)
  color = color or U.INK
  v = tonumber(v) or 0
  maxv = maxv or 100
  if v < 0 then v = 0 end
  if v > maxv then v = maxv end
  U.rect(g, x, y, w, h, color)
  local iw, ih = w - 4, h - 4
  local fw = math.floor(iw * v / maxv + 0.5)
  if fw > 0 and ih > 0 then U.fill(g, x + 2, y + 2, fw, ih, color) end
end

-- 小节标签 + 牵引细线
function U.section(g, x, y, w, label)
  local f = U.font("small")
  U.text(g, x, y, label, { font = f })
  local lw = U.measure(f, label)
  local gap = 8
  if w - lw - gap > 0 then
    U.hline(g, x + lw + gap, y + 9, w - lw - gap)
  end
end

function U.chip(g, x, y, s, o)
  o = o or {}
  local f = o.font or U.font(o.size or "small")
  local pad = o.pad or 8
  local h = o.h or 20
  s = (s == nil) and "" or tostring(s)
  local w = U.measure(f, s) + pad * 2
  if o.maxw then w = math.min(w, o.maxw) end
  if o.inverse then
    U.fill(g, x, y, w, h)
    U.text(g, x + pad, y + h // 2, s, { font = f, color = U.PAPER, valign = "middle", maxw = w - pad * 2 })
  else
    U.rect(g, x, y, w, h)
    U.text(g, x + pad, y + h // 2, s, { font = f, valign = "middle", maxw = w - pad * 2 })
  end
  return w
end

function U.tag(g, x, y, s, o)
  o = o or {}
  o.size = o.size or "small"
  o.h = o.h or 20
  o.pad = o.pad or 6
  o.color = o.color or U.PAPER
  local f = o.font or U.font(o.size)
  local s2 = (s == nil) and "" or tostring(s)
  local w = U.measure(f, s2) + o.pad * 2
  U.rect(g, x, y, w, o.h, o.color)
  U.text(g, x + o.pad, y + o.h // 2, s2, { font = f, color = o.color, valign = "middle" })
  return w
end

function U.empty(g, x, y, w, h, text)
  U.dotted(g, x, y, w, h)
  U.text(g, x + w // 2, y + h // 2, text or "（无）",
    { size = "medium", align = "center", valign = "middle", maxw = w - 24 })
end

-- ── 行 / 列表 / 页签 ─────────────────────────────────────────────
function U.rowframe(g, x, y, w, h, o)
  if not o then return end
  if o.selected then
    U.fill(g, x, y, w, h)
    if o.marker ~= false then
      U.fill(g, x - 10, y + (h - 20) // 2, 4, 20)
    end
  elseif o.disabled then
    U.dotted(g, x, y, w, h)
  end
end

-- cells: { { s=, w=, align=, gap= }, … }；选中反白 + 左标记
function U.row(g, x, y, w, h, cells, o)
  o = o or {}
  U.rowframe(g, x, y, w, h, o)
  local f = U.font(o.size or "small")
  local color = o.selected and U.PAPER or U.INK
  local cx = x + 8
  for i = 1, #cells do
    local c = cells[i]
    if c then
      local cw = c.w or 80
      local al = c.align or "left"
      local s = U.fit(f, (c.s == nil) and "" or tostring(c.s), cw)
      local tx = cx
      if al == "right" then tx = cx + cw
      elseif al == "center" then tx = cx + cw // 2 end
      U.text(g, tx, y + h // 2, s, { font = f, color = color, align = al, valign = "middle" })
      cx = cx + cw + (c.gap or 8)
    end
  end
end

function U.rowhit(hits, x, y, w, h, cmd, arg)
  hits[#hits + 1] = { x = x, y = y, w = w, h = h, cmd = cmd, arg = arg }
end

-- 页签：反白当前页；返回点击区 hits
function U.tabs(g, x, y, w, active)
  local hits = {}
  local n, h = #U.TABS, 26
  for i = 1, n do
    local tx = x + ((i - 1) * w) // n
    local tw = (i * w) // n - ((i - 1) * w) // n
    local t = U.TABS[i]
    if t.key == active then
      U.fill(g, tx, y, tw, h)
      U.text(g, tx + tw // 2, y + h // 2, t.label,
        { size = "medium", color = U.PAPER, align = "center", valign = "middle" })
    else
      U.text(g, tx + tw // 2, y + h // 2, t.label,
        { size = "medium", align = "center", valign = "middle" })
      if i > 1 then U.vline(g, tx, y + 4, h - 8) end
    end
    hits[#hits + 1] = { x = tx, y = y, w = tw, h = h, cmd = "tab", arg = t.key }
  end
  U.hline(g, x, y + h, w)
  return hits
end

function U.button(g, x, y, w, h, label, o)
  o = o or {}
  local size = o.size or "medium"
  local s = (label == nil) and "" or tostring(label)
  if o.selected then
    U.fill(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, s,
      { size = size, color = U.PAPER, align = "center", valign = "middle", maxw = w - 16 })
  elseif o.disabled then
    U.dotted(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, s,
      { size = size, align = "center", valign = "middle", maxw = w - 16 })
  else
    U.rect(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, s,
      { size = size, align = "center", valign = "middle", maxw = w - 16 })
  end
end

-- ── 页面骨架 ─────────────────────────────────────────────────────
function U.t(V, key, default)
  local tx = V and V.text
  local s = (type(tx) == "table") and tx[key] or nil
  if type(s) == "string" and s ~= "" then return s end
  return default
end

function U.hint(V, fallback)
  local h = V and V.help
  if type(h) == "string" and h ~= "" then return h end
  return fallback or "▲▼ 选择　左右 切换　OK 确认　BACK 返回"
end

function U.num(v, default)
  if type(v) == "number" then return v end
  return default or 0
end

function U.delta(v)
  v = tonumber(v)
  if not v or v == 0 then return "—" end
  if v > 0 then return "+" .. tostring(v) end
  return tostring(v)
end

-- 顶栏：左年号月，右国势/民心/健康；下双线
function U.header(g, gs)
  gs = gs or {}
  local st = gs.stats or {}
  local era = gs.era or "承平"
  local month = tonumber(gs.month) or 1
  local mt = U.MONTHS[month] or "正月"
  U.text(g, 16, 20, era .. " " .. tostring(gs.year or 1) .. " 年 · " .. mt,
    { size = "medium", valign = "middle" })
  local fs = U.font("small")
  local right = U.CX + U.CW - 8
  local items = {
    { "健康", gs.health or 0 },
    { "民心", st.min or 0 },
    { "国势", st.wang or 0 },
  }
  for i = 1, #items do
    local label, v = items[i][1], tonumber(items[i][2]) or 0
    local vs = tostring(v)
    U.text(g, right, 20, vs, { font = fs, align = "right", valign = "middle" })
    right = right - U.measure(fs, vs) - 5
    U.bar(g, right - 34, 16, 34, 8, v, 100)
    right = right - 34 - 5
    U.text(g, right, 20, label, { font = fs, align = "right", valign = "middle" })
    right = right - U.measure(fs, label) - 10
    if i < #items then
      U.vline(g, right, 13, 14)
      right = right - 10
    end
  end
  U.hline(g, 0, 32, U.W)
  U.hline(g, 0, 36, U.W)
end

function U.footer(g, hint, right)
  U.hline(g, 0, U.H - U.BOT, U.W)
  U.text(g, 16, U.H - U.BOT + 16, hint or "", { size = "small", valign = "middle" })
  if right and right ~= "" then
    U.text(g, U.W - 16, U.H - U.BOT + 16, right, { size = "small", align = "right", valign = "middle" })
  end
end

-- 缺失资源降级：2px 空框 + 中央「？」
function U.portrait(ctx, g, V, key, x, y, w, h)
  local A = V and V.A
  local ok = A and A.portrait
  if ok and A.has then ok = A.has(ctx, key) end
  if ok then
    A.portrait(ctx, g, key, x, y, w, h)
  else
    U.rect(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, "？",
      { size = "large", align = "center", valign = "middle" })
  end
end

function U.scene(ctx, g, V, key, x, y, w, h)
  local A = V and V.A
  local ok = A and A.scene
  if ok and A.has then ok = A.has(ctx, key) end
  if ok then
    A.scene(ctx, g, key, x, y, w, h)
  else
    U.rect(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, "？",
      { size = "large", align = "center", valign = "middle" })
  end
end

function U.gray(ctx, g, V, key, x, y, w, h)
  local A = V and V.A
  local ok = A and A.gray_scene
  if ok and A.has then ok = A.has(ctx, key) end
  if ok then
    A.gray_scene(ctx, g, key, x, y, w, h)
  else
    U.rect(g, x, y, w, h)
    U.text(g, x + w // 2, y + h // 2, "？",
      { size = "large", align = "center", valign = "middle" })
  end
end

-- 左栏：立绘 176×220 + 姓名/年号 + 六维条 96×8
function U.sidebar(ctx, g, V, o)
  o = o or {}
  local gs = (V and V.gs) or {}
  local st = gs.stats or {}
  local px, py, pw, ph = 36, 52, 176, 220
  local key = o.portrait
  if not key then
    key = (tonumber(gs.age) or 16) >= 55 and "p_emp_old" or "p_emp"
  end
  U.portrait(ctx, g, V, key, px, py, pw, ph)
  local name = o.name or U.t(V, "player_title", "当今陛下")
  U.text(g, 12, 276, name, { size = "medium", maxw = 216 })
  U.text(g, 12, 302, "年号 " .. tostring(gs.era or "承平") ..
    " · 春秋 " .. tostring(gs.age or 16), { size = "small", maxw = 216 })
  U.hline(g, 12, 326, 216)
  local fs = U.font("small")
  for i = 1, #U.STATS do
    local it = U.STATS[i]
    local col = (i - 1) % 2
    local row = (i - 1) // 2
    local x = 12 + col * 112
    local y = 340 + row * 32
    U.text(g, x, y, it.label, { font = fs, valign = "middle", maxw = 56 })
    U.bar(g, x + 58, y - 3, 30, 7, st[it.key] or 0, 100)
    U.text(g, x + 112, y, tostring(tonumber(st[it.key]) or 0),
      { font = fs, align = "right", valign = "middle", maxw = 26 })
  end
end

-- 页面骨架：背景、顶栏、竖分隔、左栏、页签、底栏、浮字
function U.page(ctx, g, V, o)
  o = o or {}
  U.init(ctx)
  g:clear(U.PAPER)
  local hits = {}
  if o.header ~= false then U.header(g, V and V.gs) end
  U.vline(g, U.LEFT, U.TOP, U.H - U.TOP - U.BOT)
  if o.sidebar ~= false then U.sidebar(ctx, g, V, o) end
  if o.tabs ~= false then
    local th = U.tabs(g, U.CX, U.TOP + 4, U.CW, o.tab or (V and V.tab) or (V and V.screen))
    for i = 1, #th do hits[#hits + 1] = th[i] end
  end
  U.footer(g, U.hint(V, o.hint), o.right)
  local toast = V and V.toast
  if type(toast) == "table" and type(toast.text) == "string" and toast.text ~= "" then
    local f = U.font("small")
    local tw = math.min(U.measure(f, toast.text) + 28, 420)
    local tx = U.CX + U.CW - tw
    U.paper(g, tx, 402, tw, 30)
    U.rect(g, tx, 402, tw, 30)
    U.text(g, tx + 10, 417, toast.text, { font = f, valign = "middle", maxw = tw - 20 })
  end
  return hits
end

-- 折子卡：2px 框 + 反白标题条 28
function U.card(g, x, y, w, h, title, tag)
  U.rect(g, x, y, w, h)
  U.fill(g, x + 2, y + 2, w - 4, 26)
  U.text(g, x + 10, y + 15, title or "", { size = "medium", color = U.PAPER, valign = "middle", maxw = w - 100 })
  if tag and tag ~= "" then
    U.text(g, x + w - 10, y + 15, tag, { size = "small", color = U.PAPER, align = "right", valign = "middle" })
  end
end

-- 弹窗：520×260 居中，双线框 + 反白标题；o.choices 返回点击区
function U.dialog(g, o)
  o = o or {}
  local w = o.w or 520
  local h = o.h or 260
  local x = o.x or (U.W - w) // 2
  local y = o.y or 110
  U.paper(g, x, y, w, h)
  U.rect(g, x, y, w, h)
  U.rect(g, x + 4, y + 4, w - 8, h - 8)
  U.fill(g, x + 6, y + 6, w - 12, 26)
  U.text(g, x + 14, y + 19, o.title or "", { size = "medium", color = U.PAPER, valign = "middle", maxw = w - 28 })
  if o.tag and o.tag ~= "" then
    U.text(g, x + w - 14, y + 19, o.tag, { size = "small", color = U.PAPER, align = "right", valign = "middle" })
  end
  local choices = o.choices or {}
  local body_h = o.body_h or (h - 50 - #choices * 28)
  U.body(g, x + 14, y + 44, w - 28, body_h, o.text or "", { size = "medium" })
  local hits = {}
  local cy = y + h - 10 - #choices * 28
  for i = 1, #choices do
    local c = choices[i]
    local ry = cy + (i - 1) * 28
    U.row(g, x + 14, ry, w - 28, 26, { { s = c.label, w = w - 60 } },
      { selected = c.selected, disabled = c.disabled })
    if not c.disabled then
      hits[#hits + 1] = { x = x + 14, y = ry, w = w - 28, h = 26,
                          cmd = c.cmd or "ok", arg = c.arg }
    end
  end
  return hits
end

-- 屏幕名别名 + 分发：index.lua 可一条 U.dispatch 接手
local ALIAS = { menu = "title", main = "court" }

function U.screen_module(name)
  local n = ALIAS[name or ""] or name
  if type(n) ~= "string" or n == "" then return nil end
  local ok, mod = pcall(require, "screens." .. n)
  if ok and type(mod) == "table" and type(mod.draw) == "function" then return mod end
  return nil
end

function U.dispatch(ctx, g, V)
  local mod = U.screen_module(V and V.screen)
  if mod then return mod.draw(ctx, g, V) or {} end
  U.init(ctx)
  g:clear(U.PAPER)
  U.text(g, 24, 60, "缺少界面：" .. tostring(V and V.screen), { size = "medium" })
  return {}
end

return U
