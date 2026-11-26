-- index.lua —— 皇帝成长计划 · 横屏 800×480
-- 启动 / 路由（按键·触摸）/ 月循环 / 存档；界面全部由 ui.lua 与 screens/*.lua 绘制。
local U = require("ui")
local G = require("lib.game")
local A = require("app.assets")
local Store = require("app.store")

local TABS = { "court", "decree", "harem", "court_list", "war" }
local ERAS = { "承平", "开元", "永昌" }

local ctx_, gs, V
local hits = {}
local focus = 0

-- ---------- 工具 ----------
local function toast(text)
  V.toast = { text = tostring(text or "") }
end

local function tab_at(name)
  for i = 1, #TABS do if TABS[i] == name then return i end end
  return 0
end

local function era_index(name)
  for i = 1, #ERAS do if ERAS[i] == name then return i end end
  return 1
end

local function save()
  if ctx_ and gs then Store.save(ctx_, gs) end
end

local function set_screen(name)
  V.screen = name
  if tab_at(name) > 0 then V.tab = name end
  V.cursor = 1
  V.sub = nil
  focus = 0
  V.want_start = (name == "title")
end

-- ---------- 视图快照 ----------
local function war_row(t)
  local our = (tonumber(gs.stats.jun) or 0) * 2 + (tonumber(gs.res.troops) or 0) * 3
    + (tonumber(gs.stats.cai) or 0) + (tonumber(gs.res.tech) or 0)
  local power = math.max(1, (tonumber(t.power) or 50) * 8)
  local p = math.floor(our * 1000 / (our + power))
  if p < 50 then p = 50 end
  if p > 900 then p = 900 end
  return {
    name = tostring(t.name or "—"),
    enemy = tostring(t.power or "—"),
    chance = math.floor(p / 10),
    relation = tostring(t.relation or "未服"),
    note = tostring(t.note or ""),
  }
end

local function decree_rows()
  local list = G.decree_list(gs) or {}
  local out = {}
  for i = 1, #list do
    local it = list[i]
    local cost = it.cost or {}
    local bits = {}
    if (tonumber(cost.gold) or 0) ~= 0 then bits[#bits + 1] = "银" .. tostring(cost.gold) end
    if (tonumber(cost.grain) or 0) ~= 0 then bits[#bits + 1] = "粮" .. tostring(cost.grain) end
    local hint = tostring(it.hint or "")
    if #bits > 0 then hint = hint .. "（" .. table.concat(bits, " ") .. "）" end
    local tag = ""
    if it.used then tag = "已行" elseif not it.afford then tag = "不足" elseif it.ok then tag = "可行" end
    out[i] = { name = tostring(it.name or "—"), hint = hint, tag = tag, done = it.used == true }
  end
  return out
end

local function snapshot()
  local v = G.save_view(gs)
  v.screen = V.screen
  v.tab = V.tab
  v.cursor = V.cursor
  v.sub = V.sub
  v.candidates = V.candidates
  v.toast = V.toast
  v.has_save = Store.has(ctx_)
  v.era_index = tonumber(V.era_index) or era_index(gs.era)
  v.diff_index = tonumber(V.diff_index) or tonumber(gs.difficulty) or 2
  if V.screen == "decree" then
    v.decrees = decree_rows()
  elseif V.screen == "war" then
    local out, list = {}, G.targets() or {}
    for i = 1, #list do out[i] = war_row(list[i]) end
    v.war_targets = out
  end
  return v
end

local function refresh()
  V.gs = snapshot()
  V.A = A
  V.U = U
end

-- ---------- 焦点 ----------
local function nav_positions()
  local out = {}
  for i = 1, #hits do
    local h = hits[i]
    if type(h) == "table" and h.cmd and h.cmd ~= "tab" and (h.w or 0) > 0 then out[#out + 1] = i end
  end
  return out
end

local function list_total()
  if V.screen == "decree" then return #(V.gs.decrees or {}) end
  if V.screen == "court_list" then return #(gs.court or {}) end
  if V.screen == "harem" then
    local rows = (V.sub == "pick" and V.candidates) or gs.harem or {}
    return math.min(#rows, 5)
  end
  if V.screen == "war" then return #(V.gs.war_targets or {}) end
  if V.screen == "court" then
    local p = gs.pending
    if type(p) == "table" and type(p.result) == "string" and p.result ~= "" then return 0 end
    local ev = current_event()
    return ev and #(ev.choices or {}) or 0
  end
  return 0
end

local function clamp_focus()
  local nav = nav_positions()
  if #nav == 0 then focus = 0 return end
  local ok = false
  for i = 1, #nav do if nav[i] == focus then ok = true break end end
  if not ok then focus = nav[1] end
end

local function step_focus(dir)
  local nav = nav_positions()
  if #nav == 0 then focus = 0 return end
  V.want_start = nil
  clamp_focus()
  local h = hits[focus]
  local total = list_total()
  -- 行列表翻页：停在页尾再按下，光标越页
  if dir > 0 and h and h.cmd == "select" and total > 0 then
    local c = tonumber(h.arg) or 0
    local last_sel = true
    for k = 1, #nav do
      local o = hits[nav[k]]
      if o.cmd == "select" and nav[k] > focus then last_sel = false end
    end
    if last_sel and c < total then
      V.cursor = c + 1
      focus = nav[1]
      return
    end
  end
  local pos = 1
  for i = 1, #nav do if nav[i] == focus then pos = i end end
  local nxt = pos + dir
  if nxt < 1 then nxt = 1 end
  if nxt > #nav then nxt = #nav end
  focus = nav[nxt]
  local o = hits[focus]
  if o and o.cmd == "select" and o.arg then V.cursor = tonumber(o.arg) or V.cursor end
end

-- ---------- 业务 ----------
function current_event()
  local p = gs and gs.pending
  if type(p) == "table" and type(p.choices) == "table" and #p.choices > 0 then return p end
  local q = gs and gs.queue
  if type(q) == "table" and type(q[1]) == "table" then return q[1] end
  return nil
end

local function pending_text()
  local p = gs.pending
  if type(p) == "table" and type(p.result) == "string" and p.result ~= "" then return p.result end
  return nil
end

local function court_resolve(i)
  local ev = current_event()
  if not ev then toast("本月无折子。") return end
  local out = G.resolve_issue(gs, ev, i)
  if type(gs.pending) == "table" and type(out) == "table" then
    gs.pending.result = tostring(out.text or "已批。")
  end
  save()
end

local function court_continue()
  gs.pending = nil
  if #(gs.queue or {}) > 0 then
    save()
  else
    set_screen("summary")
    save()
  end
end

local function seed_now()
  local ok, v = pcall(function() return ctx_.clock:millis() end)
  if ok and type(v) == "number" then return (v % 2147483646) + 1 end
  return 12345
end

local function start_game()
  local diff = tonumber(V.diff_index) or 2
  local ei = tonumber(V.era_index) or era_index(gs.era)
  local era = ERAS[ei] or "承平"
  V.era_index = ei
  gs = G.new({ difficulty = diff, era = era, seed = seed_now() })
  G.start_month(gs)
  V.candidates, V.sub = nil, nil
  set_screen("court")
  toast("改元" .. era .. "，新政伊始。")
  save()
end

local function load_game()
  local loaded = Store.load(ctx_)
  if loaded then
    gs = loaded
    if type(gs.ended) == "table" then set_screen("ending") else set_screen("court") end
    toast("旧档已启。")
  else
    toast("并无旧档。")
  end
end

local function advance_month()
  gs = G.advance_month(gs) or gs
  V.candidates, V.sub = nil, nil
  if type(gs.ended) == "table" then
    set_screen("ending")
  else
    set_screen("court")
  end
  save()
end

local function switch_tab(dir)
  local cur = tab_at(V.tab)
  if cur == 0 then cur = 1 end
  local nxt = cur + dir
  if nxt < 1 then nxt = #TABS end
  if nxt > #TABS then nxt = 1 end
  V.prev_screen = V.screen
  V.screen = TABS[nxt]
  V.tab = TABS[nxt]
  V.cursor, V.sub, focus = 1, nil, 0
end

local function do_action(arg)
  local a = tostring(arg or "")
  local kind, val = a:match("^(%w+):(.*)$")
  if kind == "era" then
    V.era_index = era_index(val)
    V.era_name = val
    return
  end
  if kind == "difficulty" then
    V.diff_index = tonumber(val) or 2
    return
  end
  if a == "help" then
    V.prev_screen = "title"
    set_screen("help")
    return
  end
  if a == "crown" then
    local n = #(gs.heirs or {})
    if n == 0 then toast("尚无皇子。") return end
    local out = G.crown(gs, 1)
    toast(out and out.text or "已立储。")
    save()
    return
  end
  if a == "appoint" then
    local cand = gs.flags and gs.flags.keju_candidate
    if type(cand) ~= "table" then toast("朝无新科，先开科取士。") return end
    local out = G.appoint(gs, cand)
    if out and out.ok then gs.flags.keju_candidate = nil end
    toast(out and out.text or "已授官。")
    save()
    return
  end
  if a == "dismiss" then
    local out = G.dismiss(gs, V.cursor)
    toast(out and out.text or "已罢。")
    save()
    return
  end
  if a == "reward" then
    local c = (gs.court or {})[V.cursor]
    if type(c) ~= "table" then toast("未选臣僚。") return end
    if (tonumber(gs.res.gold) or 0) < 10 then toast("府库不足十金。") return end
    G.apply(gs, { gold = -10 })
    c.loyalty = math.min(100, (tonumber(c.loyalty) or 50) + 6)
    toast("赐" .. tostring(c.name) .. "帛十匹。")
    save()
    return
  end
  if a == "impeach" then
    local c = (gs.court or {})[V.cursor]
    if type(c) ~= "table" then toast("未选臣僚。") return end
    if (tonumber(c.loyalty) or 50) < 45 then
      local nm = tostring(c.name or "此人")
      G.apply(gs, { wei = 2, corr = 2 })
      G.dismiss(gs, V.cursor)
      toast("查有实据，" .. nm .. "下狱。")
    else
      G.apply(gs, { min = -2, de = -1 })
      toast("查无实据，反伤人心。")
    end
    save()
    return
  end
  if a == "back" then
    set_screen(V.prev_screen or "title")
    return
  end
  toast("此事未明。")
end

local function do_ok(arg)
  local a = tostring(arg or "")
  local sc = V.screen

  if sc == "title" then
    if a == "start" then start_game()
    elseif a == "continue" then load_game()
    elseif a == "help" then
      V.prev_screen = "title"
      set_screen("help")
    end
    return
  end

  if sc == "court" then
    if a == "continue" then court_continue()
    elseif a == "next_month" then set_screen("summary")
    else court_resolve(V.cursor) end
    return
  end

  if sc == "summary" then
    if a == "next_month" then advance_month() end
    return
  end

  if sc == "decree" and a == "decree" then
    local list = G.decree_list(gs) or {}
    local it = list[V.cursor]
    if type(it) ~= "table" then toast("未选诏令。") return end
    local out = G.apply_decree(gs, it.id)
    toast(out and out.text or "诏令已下。")
    save()
    return
  end

  if sc == "harem" then
    if a == "pick" then
      V.sub = "pick"
      V.candidates = G.harem_picks(gs)
      V.cursor, focus = 1, 0
    elseif a == "pick_done" then
      local out = G.take_consort(gs, V.cursor)
      if out and out.ok then V.sub, V.candidates, V.cursor = nil, nil, 1 end
      toast(out and out.text or "无人可选。")
      save()
    elseif a == "visit" then
      local out = G.visit(gs, V.cursor)
      toast(out and out.text or "无人可幸。")
      save()
    end
    return
  end

  if sc == "court_list" and a == "keju" then
    local cand = G.open_keju(gs)
    if type(cand) == "table" then
      toast("取士：" .. tostring(cand.name or "") .. " · " .. tostring(cand.hint or ""))
    else
      toast("今年已开科，或府库不足。")
    end
    save()
    return
  end

  if sc == "war" then
    if a == "war" then
      local t = (G.targets() or {})[V.cursor]
      local out = G.war(gs, t)
      toast(out and out.text or "战报未至。")
      save()
    elseif a == "peace" then
      local out = G.peace(gs)
      toast(out and out.text or "和议已成。")
      save()
    elseif a == "fortify" then
      if (tonumber(gs.res.gold) or 0) < 10 then toast("府库不足，难修边墙。") return end
      G.apply(gs, { gold = -10, jun = 3, wei = 2 })
      toast("拨银十万贯，戍卒加饷。")
      save()
    end
    return
  end

  if sc == "ending" and a == "restart" then
    Store.clear(ctx_)
    gs = G.new({ difficulty = tonumber(V.diff_index) or 2 })
    V.era_index, V.candidates, V.sub = nil, nil, nil
    set_screen("title")
    save()
    return
  end

  if sc == "help" and (a == "close_help" or a == "back") then
    set_screen(V.prev_screen or "title")
    return
  end

  toast("此处无可为。")
end

local function execute(cmd, arg)
  if cmd == "tab" then
    V.prev_screen = V.screen
    V.screen = tostring(arg or V.tab)
    V.tab = V.screen
    V.cursor, V.sub, focus = 1, nil, 0
    return
  end
  if cmd == "select" then
    V.cursor = tonumber(arg) or 1
    if V.screen == "court" then court_resolve(V.cursor) end
    return
  end
  if cmd == "action" then do_action(arg) return end
  if cmd == "ok" then do_ok(arg) return end
end

-- OK 键：行上按主操作，按钮/页签按命中区
local function confirm()
  clamp_focus()
  local h = hits[focus]
  if not h then
    if V.screen == "court" then court_resolve(V.cursor) end
    return
  end
  if h.cmd == "select" then
    local sc = V.screen
    if sc == "court" then
      court_resolve(tonumber(h.arg) or V.cursor)
    elseif sc == "decree" then
      V.cursor = tonumber(h.arg) or V.cursor
      do_ok("decree")
    elseif sc == "harem" then
      V.cursor = tonumber(h.arg) or V.cursor
      do_ok(V.sub == "pick" and "pick_done" or "visit")
    elseif sc == "war" then
      V.cursor = tonumber(h.arg) or V.cursor
      do_ok("war")
    elseif sc == "court_list" then
      V.cursor = tonumber(h.arg) or V.cursor
      do_action("appoint")
    end
    return
  end
  execute(h.cmd, h.arg)
end

-- ---------- 绘制焦点竖条 ----------
local function focus_bar(g)
  local h = hits[focus]
  if type(h) ~= "table" or not h.cmd or h.cmd == "tab" then return end
  local bh = math.max(6, (tonumber(h.h) or 0) - 6)
  U.fill(g, (tonumber(h.x) or 0) - 4, (tonumber(h.y) or 0) + 3, 3, bh)
end

-- ---------- 生命周期 ----------
function on_load(ctx)
  ctx_ = ctx
  U.init(ctx)
  A.reset()
  V = { screen = "title", tab = "court", cursor = 1, sub = nil, diff_index = 2, want_start = true }
  V.has_save = Store.has(ctx)
  gs = G.new({ difficulty = 2 })
  V.era_index = era_index(gs.era)
  refresh()
end

function on_draw(ctx, g)
  gs = gs or G.new({ difficulty = 2 })
  refresh()
  hits = U.dispatch(ctx, g, V) or {}
  clamp_focus()
  if V.want_start then
    for i = 1, #hits do
      local h = hits[i]
      if type(h) == "table" and h.cmd == "ok" and h.arg == "start" then
        focus = i
        V.want_start = nil
      end
    end
  end
  focus_bar(g)
  V.toast = nil
end

local function tap(x, y)
  for i = #hits, 1, -1 do
    local h = hits[i]
    if type(h) == "table" and h.cmd then
      local hx, hy, hw, hh = tonumber(h.x), tonumber(h.y), tonumber(h.w), tonumber(h.h)
      if hx and hy and hw and hh and x >= hx and x <= hx + hw and y >= hy and y <= hy + hh then
        focus = i
        if h.cmd == "select" then
          V.cursor = tonumber(h.arg) or 1
          if V.screen == "court" then court_resolve(V.cursor) end
        else
          execute(h.cmd, h.arg)
        end
        return true
      end
    end
  end
  return false
end

local function kick(ctx)
  if ctx then pcall(function() ctx:invalidate() end) end
end

function on_input(ctx, ev)
  if type(ev) ~= "table" then return false end
  if ev.type == "key" then
    if ev.phase ~= "down" then return true end
    local k = ev.key
    if k == "up" then
      step_focus(-1)
    elseif k == "down" then
      step_focus(1)
    elseif k == "left" or k == "right" then
      if V.screen == "title" or V.screen == "help" or V.screen == "ending" then return true end
      switch_tab(k == "right" and 1 or -1)
    elseif k == "ok" then
      confirm()
    elseif k == "back" then
      if V.screen == "title" then
        return true
      elseif V.screen == "help" then
        set_screen(V.prev_screen or "title")
      else
        V.prev_screen = V.screen
        set_screen("title")
      end
    end
    kick(ctx)
    return true
  end
  if ev.type == "pointer" then
    if ev.phase == "up" then
      local x, y = tonumber(ev.x), tonumber(ev.y)
      if x and y then tap(x, y) end
      kick(ctx)
      return true
    end
    return false
  end
  return false
end
