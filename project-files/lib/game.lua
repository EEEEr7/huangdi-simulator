-- lib/game.lua：皇帝成长计划·规则（纯 Lua、纯整数、禁止 ctx，≤400 行）
-- 数值口径见 docs/01-design.md §2/§3；小数公式改整数等价式，万贯/万石四舍五入。
-- 存档不含浮点：数值一律 int()，save_view 输出可 JSON 化的纯表（无函数/无环、深度≤6）。
local RNG = require("lib.rng")
local G = {}
local STAT_KEYS = { "wang", "min", "jun", "wei", "cai", "de" }
local RES_KEYS = { "gold", "grain", "troops", "pop", "corr", "tech" }
local LABEL = { wang = "国势", min = "民心", jun = "军心", wei = "威望", cai = "才略", de = "德行" }
local RES_LABEL = { gold = "银", grain = "粮", troops = "兵", pop = "民", corr = "吏", tech = "技" }
local TAX = { [1] = 900, [2] = 1000, [3] = 1150 } -- 税率千分比 0.9/1.0/1.15
local MONTHS = { "正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二" }
local DIG = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
local DEPTS = { "吏", "户", "礼", "兵", "刑", "工" }
local STATE_KEYS = { "year", "month", "age", "era", "difficulty", "stats", "res", "health", "harem",
  "heirs", "court", "edicts", "flags", "log", "rng", "ended", "phase", "queue", "pending", "month_effects" }
local END_T = { death_ill = "病逝", rebellion = "民变", mutiny = "兵变", long_life = "寿终", prosper = "盛世" }
local END_X = { death_ill = "积劳成疾，崩于乾清宫。", rebellion = "流民四起，京师陷落。",
  mutiny = "禁军哗变，宫门洞开。", long_life = "在位日久，寿终正寝。", prosper = "海内殷富，四夷宾服。" }

-- ---------- 数据加载：队友文件缺失/半成品时用内置兜底 ----------
local function load(n)
  local ok, t = pcall(require, n)
  if ok and type(t) == "table" then return t end
end
local EVM, DECM, NAM, ENDM = load("lib.data.events"), load("lib.data.decrees"),
  load("lib.data.names"), load("lib.data.endings")
-- 兼容纯数组 / { events = {...} } / id 映射表
local function as_list(m, f)
  if type(m) ~= "table" then return nil end
  if #m > 0 then return m end
  if type(m[f]) == "table" and #m[f] > 0 then return m[f] end
  if type(m.list) == "table" and #m.list > 0 then return m.list end
  local out = {}
  for _, v in pairs(m) do if type(v) == "table" and v.id then out[#out + 1] = v end end
  table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
  return out
end

-- 内置 3 条兜底事件 / 4 条诏令 / 名字池（正式数据由 lib/data 队友提供）
local FB_EVENTS = {
  { id = "fb_flood", tag = "天灾", weight = 20, title = "黄河决口",
    text = "河决曹州，流民塞道，郡守请发帑赈济。",
    choices = { { label = "发赈", hint = "银 -30 民 +6", effect = { gold = -30, min = 6 } },
      { label = "不报", hint = "民 -8 吏 -4", effect = { min = -8, corr = -4 } } } },
  { id = "fb_border", tag = "边患", weight = 15, title = "匈奴犯边",
    text = "胡骑三千叩关，边将飞章告急。",
    choices = { { label = "出兵", hint = "兵 -4 威 +5", effect = { troops = -4, wei = 5, gold = -10 } },
      { label = "和亲", hint = "银 -20 威 -3", effect = { gold = -20, wei = -3, min = 2 } } } },
  { id = "fb_court", tag = "朝争", weight = 12, title = "御史弹劾",
    text = "御史劾首辅纳贿，朝议汹汹。",
    choices = { { label = "查办", hint = "吏 +4 威 +3", effect = { corr = 4, wei = 3, cai = 2 } },
      { label = "留中", hint = "吏 -3 民 -2", effect = { corr = -3, min = -2 } } } },
}
local FB_DECREES = {
  { id = "keju", name = "开科取士", hint = "银 -10 才 +4 威 +2", cost = { gold = 10 }, effect = { cai = 4, wei = 2 } },
  { id = "relief", name = "赈灾减税", hint = "银 -15 民 +6", cost = { gold = 15 }, effect = { min = 6 } },
  { id = "river", name = "修河筑堤", hint = "银 -20 民 +4 技 +3", cost = { gold = 20 }, effect = { min = 4, tech = 3, corr = -2 } },
  { id = "levy", name = "征兵扩军", hint = "银 -10 兵 +8 民 -3", cost = { gold = 10 }, effect = { troops = 8, min = -3 } },
}
local FB_MALE = { "沈砚", "李崇", "周允", "徐阶", "高拱", "王守仁", "杨廷和", "申时行", "于谦", "张璁" }
local FB_FEMALE = { "苏婉", "柳如烟", "沈云裳", "李师师", "赵飞燕", "王昭君", "陈圆圆", "董小宛" }
local EVLIST = as_list(EVM, "events")
if not EVLIST or #EVLIST == 0 then EVLIST = FB_EVENTS end
local DECLIST = as_list(DECM, "decrees")
if not DECLIST or #DECLIST == 0 then DECLIST = FB_DECREES end
local ENEMIES = { { name = "匈奴", power = 70, loot = 40 }, { name = "南越", power = 45, loot = 25 },
  { name = "西羌", power = 50, loot = 20 }, { name = "高丽", power = 30, loot = 15 } }

-- ---------- 基础工具 ----------
local function int(v, d)
  v = tonumber(v)
  return v and math.floor(v) or d
end
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function round_div(n, d) -- 四舍五入整数除法，d>0
  if n >= 0 then return (n + d // 2) // d end
  return -((-n + d // 2) // d)
end
-- 深拷贝为纯数据：丢函数/断环；save 用
local function plain(v, seen)
  local t = type(v)
  if t ~= "table" then
    if t == "function" or t == "userdata" or t == "thread" then return nil end
    return v
  end
  seen = seen or {}
  if seen[v] then return nil end
  seen[v] = true
  local out = {}
  for k, x in pairs(v) do
    if type(k) == "string" or type(k) == "number" then
      local c = plain(x, seen)
      if c ~= nil then out[k] = c end
    end
  end
  seen[v] = nil
  return out
end
local function push_log(s, text)
  s.log[#s.log + 1] = tostring(text)
  while #s.log > 12 do table.remove(s.log, 1) end
end
local function cn_num(n)
  n = int(n, 0)
  if n <= 1 then return n == 1 and "元" or "零" end
  if n < 10 then return DIG[n + 1] end
  if n < 20 then return "十" .. (n % 10 > 0 and DIG[n % 10 + 1] or "") end
  if n < 100 then return DIG[n // 10 + 1] .. "十" .. (n % 10 > 0 and DIG[n % 10 + 1] or "") end
  return tostring(n)
end
local function date_text(s)
  return tostring(s.era or "承平") .. cn_num(s.year) .. "年 " .. (MONTHS[clamp(int(s.month, 1), 1, 12)]) .. "月"
end
local function hp_cap(s) return int(s.age, 16) >= 55 and 90 or 100 end -- 55 岁后健康上限 90
local function record(s, k, d)
  if d ~= 0 then s.month_effects[k] = int(s.month_effects[k], 0) + d end
end

-- ---------- 名字与结局（可被 lib/data 覆盖） ----------
local function find_ev(id)
  for _, e in ipairs(EVLIST) do if e.id == id then return e end end
end
local function name_pool(kind)
  if type(NAM) == "table" then
    local p = NAM[kind] or (type(NAM.names) == "table" and NAM.names[kind])
    if type(p) == "table" and #p > 0 then return p end
    if #NAM > 0 then return NAM end
  end
  return kind == "female" and FB_FEMALE or FB_MALE
end
local function take_name(s, kind, used)
  local pool = name_pool(kind)
  for _ = 1, 12 do
    local nm = pool[RNG.range(s, 1, #pool)]
    if not used or not used[nm] then
      if used then used[nm] = true end
      return nm
    end
  end
  return pool[RNG.range(s, 1, #pool)]
end
local function ending(id)
  local m = ENDM
  if type(m) == "table" then
    local v = m[id] or (type(m.by_id) == "table" and m.by_id[id]) or m.default
    if type(m.pick) == "function" then
      local ok, r = pcall(m.pick, id)
      if ok and r ~= nil then v = r end
    end
    if type(v) == "string" then return { id = id, title = END_T[id] or id, text = v } end
    if type(v) == "table" then return { id = id, title = v.title or END_T[id] or id, text = v.text or "" } end
    for _, x in ipairs(m) do
      if type(x) == "table" and x.id == id then
        return { id = id, title = x.title or END_T[id] or id, text = x.text or "" }
      end
    end
  end
  return { id = id, title = END_T[id] or id, text = END_X[id] or "朕崩于位，社稷易主。" }
end

-- ---------- 开局 ----------
-- opts = { difficulty = 1..3, era = "承平", seed = 整数, age = 16 }
function G.new(opts)
  opts = type(opts) == "table" and opts or {}
  local s = {
    year = 1, month = 1, age = int(opts.age, 16),
    era = type(opts.era) == "string" and opts.era or "承平",
    difficulty = clamp(int(opts.difficulty, 1), 1, 3),
    stats = { wang = 50, min = 50, jun = 50, wei = 50, cai = 50, de = 50 },
    res = { gold = 120, grain = 200, troops = 20, pop = 1000, corr = 50, tech = 30 },
    health = 90,
    harem = { { name = "皇后", favor = 60, son = 0, wife = true } },
    heirs = {}, court = { { name = "张居正", dept = "礼", loyalty = 70, skill = 60 } },
    edicts = {},
    flags = { keju_year = 1, deficit = false, deficit_gold = false, deficit_grain = false,
      recent = {}, seen = {} },
    log = {}, rng = int(opts.seed, 12345), ended = nil, phase = "court",
    queue = {}, pending = nil, month_effects = {},
  }
  RNG.set(s, s.rng)
  push_log(s, date_text(s) .. "，朕登基，改元" .. s.era .. "。")
  return s
end

-- ---------- 增减与裁剪 ----------
-- 返回实际生效增量；六维/官纪/技艺裁 0..100，兵/民不为负；银/粮可为负并留赤字标记。
function G.apply(s, effects)
  local ch = {}
  if type(s) ~= "table" or type(effects) ~= "table" then return ch end
  s.flags = type(s.flags) == "table" and s.flags or {}
  s.month_effects = type(s.month_effects) == "table" and s.month_effects or {}
  for _, k in ipairs(STAT_KEYS) do
    if type(effects[k]) == "number" then
      local old, new = int(s.stats[k], 0), clamp(int(s.stats[k], 0) + int(effects[k], 0), 0, 100)
      if new ~= old then s.stats[k], ch[k] = new, new - old; record(s, k, new - old) end
    end
  end
  for _, k in ipairs(RES_KEYS) do
    if type(effects[k]) == "number" then
      local old, new = int(s.res[k], 0), int(s.res[k], 0) + int(effects[k], 0)
      if k == "corr" or k == "tech" then new = clamp(new, 0, 100)
      elseif k == "troops" or k == "pop" then new = math.max(0, new) end
      if new ~= old then s.res[k], ch[k] = new, new - old; record(s, k, new - old) end
    end
  end
  if type(effects.health) == "number" then
    local old, new = int(s.health, 0), clamp(int(s.health, 0) + int(effects.health, 0), 0, hp_cap(s))
    if new ~= old then s.health, ch.health = new, new - old; record(s, "health", new - old) end
  end
  if int(s.res.gold, 0) < 0 then s.flags.deficit_gold = true end
  if int(s.res.grain, 0) < 0 then s.flags.deficit_grain = true end
  if s.flags.deficit_gold or s.flags.deficit_grain then s.flags.deficit = true end
  return ch
end
function G.statline(s)
  local out = {}
  for _, k in ipairs(STAT_KEYS) do out[#out + 1] = { LABEL[k], int(s.stats[k], 0) } end
  return out
end
function G.tax_rate(s) return TAX[clamp(int(s.difficulty, 1), 1, 3)] or 1000 end
local function tax_of(s) -- 税银 = pop*0.012*corr/100*rate → pop*12*corr*rate/1e8，四舍五入
  return round_div(int(s.res.pop, 0) * 12 * int(s.res.corr, 0) * G.tax_rate(s), 100000000)
end
local function upkeep_of(s) return round_div(int(s.res.troops, 0) * 16, 10) end
local function grain_in_of(s) -- 粮入：每月 pop*0.05*min/100；九、十月秋收再加 0.15 份
  local pop, minv, m = int(s.res.pop, 0), int(s.stats.min, 0), int(s.month, 1)
  local g = pop * 5 * minv // 10000
  if m == 9 or m == 10 then g = g + pop * 15 * minv // 10000 end
  return g
end
function G.preview(s)
  return { tax = tax_of(s), upkeep = upkeep_of(s), grain_in = grain_in_of(s), tax_rate = G.tax_rate(s) }
end

-- ---------- 折子 ----------
local function candidates(s, used)
  local y, out = int(s.year, 1), {}
  for _, e in ipairs(EVLIST) do
    if e.id and not used[e.id] and not (e.once and s.flags.seen[e.id])
      and y >= int(e.min_year, 0) and y <= int(e.max_year, 9999) then out[#out + 1] = e end
  end
  return out
end
local function weighted(s, pool)
  local total = 0
  for i = 1, #pool do total = total + math.max(1, int(pool[i].weight, 10)) end
  if total <= 0 then return nil end
  local r = RNG.range(s, 1, total)
  for i = 1, #pool do
    r = r - math.max(1, int(pool[i].weight, 10))
    if r <= 0 then return pool[i] end
  end
  return pool[#pool]
end
-- 抽本月 1~2 折子写 queue；最近 6 条不重复
function G.draw_issues(s)
  if s.ended then return s.queue end
  s.queue = {}
  local n = 1 + (RNG.chance(s, 400) and 1 or 0)
  local used, recent = {}, {}
  for _, id in ipairs(s.flags.recent or {}) do recent[id] = true end
  for _ = 1, n do
    local pool = candidates(s, used)
    if #pool == 0 then break end
    local fresh = {}
    for _, e in ipairs(pool) do if not recent[e.id] then fresh[#fresh + 1] = e end end
    local pick = weighted(s, #fresh > 0 and fresh or pool)
    if not pick then break end
    used[pick.id] = true
    s.queue[#s.queue + 1] = pick
    s.flags.seen[pick.id] = true
    s.flags.recent[#s.flags.recent + 1] = pick.id
  end
  while #s.flags.recent > 6 do table.remove(s.flags.recent, 1) end
  s.pending = nil
  return s.queue
end
local function find_event(s, id)
  return find_ev(id) or (function()
    for _, e in ipairs(s.queue or {}) do if type(e) == "table" and e.id == id then return e end end
  end)()
end
-- 选项没有写 result 文案时，用实际生效的增减拼一句，别只回一句光秃秃的选项名
local function fmt_fx(fx)
  local parts = {}
  for _, k in ipairs(STAT_KEYS) do
    local v = tonumber(fx[k])
    if v and v ~= 0 then parts[#parts + 1] = LABEL[k] .. (v > 0 and "+" or "") .. tostring(v) end
  end
  for _, k in ipairs(RES_KEYS) do
    local v = tonumber(fx[k])
    if v and v ~= 0 then parts[#parts + 1] = RES_LABEL[k] .. (v > 0 and "+" or "") .. tostring(v) end
  end
  return table.concat(parts, "，")
end

-- 应用 event.choices[idx].effect，返回 { text, effects, tags, title, id }
function G.resolve_issue(s, event, idx)
  if type(event) == "string" then event = find_event(s, event) end
  local out = { text = "", effects = {}, tags = {} }
  if type(event) ~= "table" then out.text = "此事无凭，留待后议。"; return out end
  if event.tag then out.tags[#out.tags + 1] = event.tag end
  local c = (event.choices or {})[int(idx, 1)]
  if type(c) ~= "table" then out.text = "未作决断，事遂寝。"; return out end
  out.effects = G.apply(s, c.effect or {})
  out.text = tostring(c.result or c.text or "")
  if out.text == "" then
    local fx = fmt_fx(out.effects or {})
    out.text = tostring(c.label or event.title or "已决") .. "。" ..
      (fx ~= "" and ("（" .. fx .. "）") or "此事已了。")
  end
  out.title, out.id, out.choice = event.title, event.id, c.label
  for i = #s.queue, 1, -1 do
    if s.queue[i] == event or (type(s.queue[i]) == "table" and s.queue[i].id == event.id) then
      table.remove(s.queue, i)
    end
  end
  s.pending = { kind = "issue", id = event.id, title = event.title, text = out.text,
    effects = plain(out.effects), tags = plain(out.tags) }
  push_log(s, out.text)
  return out
end

-- ---------- 月循环 ----------
local function settle(s)
  s.month_effects = {}
  local tax, up, gin = tax_of(s), upkeep_of(s), grain_in_of(s)
  s.flags.monthly = { tax = tax, upkeep = up, grain_in = gin, gold = tax, grain = gin - up }
  G.apply(s, { gold = tax, grain = gin - up })
  s.flags.deficit_gold = int(s.res.gold, 0) < 0
  s.flags.deficit_grain = int(s.res.grain, 0) < 0
  s.flags.deficit = s.flags.deficit_gold or s.flags.deficit_grain
  if s.flags.deficit_gold then G.apply(s, { min = -2, wang = -1 }) end
  if s.flags.deficit_grain then G.apply(s, { min = -3, jun = -3 }) end
  G.apply(s, { health = -(1 + int(s.age, 16) // 20) })
  if int(s.health, 0) > 0 and int(s.health, 0) < 60 then G.apply(s, { health = 1 }) end -- 太医调养
end
-- 当月结算（税银/粮入/耗粮/健康）→ 结局 → 抽折子
function G.start_month(s)
  if s.ended then return s end
  settle(s)
  if G.check_end(s) then return s end
  s.phase = "court"
  G.draw_issues(s)
  return s
end
-- 推进一月：跨年 age+1、清诏令、55 岁起每年 -6；再结算新月份
function G.next_month(s)
  if s.ended then return s end
  local m = int(s.month, 1) + 1
  if m > 12 then
    m = 1
    s.year, s.age = int(s.year, 1) + 1, int(s.age, 16) + 1
    s.edicts, s.flags.keju_year, s.flags.decree_month = {}, s.year, nil
    if s.age >= 55 then G.apply(s, { health = -6 }) end
    push_log(s, date_text(s) .. "，新岁，改元如故。")
  end
  s.month = m
  return G.start_month(s)
end
-- 结局：health > min > jun，其次寿终/盛世；设置 ended 与 phase=over
function G.check_end(s)
  if s.ended then return s.ended end
  local id
  if int(s.health, 0) <= 0 then id = "death_ill"
  elseif int(s.stats.min, 0) <= 0 then id = "rebellion"
  elseif int(s.stats.jun, 0) <= 0 then id = "mutiny"
  elseif int(s.age, 0) >= 70 then id = "long_life"
  elseif int(s.age, 0) >= 60 and int(s.stats.min, 0) >= 80 and int(s.stats.wei, 0) >= 80
    and int(s.stats.cai, 0) >= 80 then id = "prosper" end
  if id then
    s.ended, s.phase = ending(id), "over"
    push_log(s, "——" .. tostring(s.ended.text or ""))
  end
  return s.ended
end

-- ---------- 诏令 ----------
local function cost_of(d)
  local c = d.cost
  if type(c) == "number" then return int(c, 0), 0 end
  if type(c) == "table" then return int(c.gold, 0), int(c.grain, 0) end
  return 0, 0
end
function G.decree_list(s)
  local out, key = {}, int(s.year, 1) * 12 + int(s.month, 1)
  for _, d in ipairs(DECLIST) do
    local gold, grain = cost_of(d)
    local afford = int(s.res.gold, 0) >= gold and int(s.res.grain, 0) >= grain
    out[#out + 1] = { id = d.id, name = d.name or d.id, hint = d.hint or "",
      cost = { gold = gold, grain = grain }, used = s.edicts[d.id] == true, afford = afford,
      ok = afford and not s.edicts[d.id] and s.flags.decree_month ~= key }
  end
  return out
end
function G.apply_decree(s, id)
  local key = int(s.year, 1) * 12 + int(s.month, 1)
  if s.flags.decree_month == key then return { ok = false, text = "本月诏令已下，且待来月。" } end
  local d
  for _, x in ipairs(DECLIST) do if x.id == id then d = x end end
  if not d then return { ok = false, text = "无此诏令。" } end
  if s.edicts[id] then return { ok = false, text = "此诏本年已行。" } end
  local gold, grain = cost_of(d)
  if int(s.res.gold, 0) < gold or int(s.res.grain, 0) < grain then return { ok = false, text = "钱粮不足。" } end
  G.apply(s, { gold = -gold, grain = -grain })
  G.apply(s, d.effect or {})
  s.edicts[id], s.flags.decree_month = true, key
  local text = "诏令已下：" .. tostring(d.name or id)
  push_log(s, text)
  return { ok = true, text = text }
end

-- ---------- 后宫 ----------
function G.harem_picks(s)
  local picks, used = {}, {}
  for i = 1, 3 do
    picks[i] = { name = take_name(s, "female", used), beauty = RNG.range(s, 40, 90),
      talent = RNG.range(s, 30, 85), favor = 30 }
  end
  s.flags.harem_picks = picks
  return picks
end
function G.take_consort(s, i)
  local picks, idx = s.flags.harem_picks or {}, int(i, 0)
  local p = picks[idx]
  if type(p) ~= "table" then return { ok = false, text = "无人可选。" } end
  if #s.harem >= 8 then return { ok = false, text = "后宫已满。" } end
  local c = { name = p.name, favor = 40, son = 0, wife = false,
    beauty = int(p.beauty, 50), talent = int(p.talent, 50) }
  s.harem[#s.harem + 1] = c
  table.remove(picks, idx)
  push_log(s, tostring(p.name) .. "入宫，封为嫔御。")
  return { ok = true, text = "纳" .. tostring(p.name) .. "入宫。", consort = c }
end
-- 临幸：健康 -2（Lead 定稿）、favor +8、按 favor 判定子嗣
function G.visit(s, i)
  local c = (s.harem or {})[int(i, 0)]
  if type(c) ~= "table" then return { ok = false, text = "无人可幸。" } end
  if int(s.health, 0) <= 10 then return { ok = false, text = "圣躬不豫，宜静养。" } end
  G.apply(s, { health = -2 })
  c.favor = clamp(int(c.favor, 0) + 8, 0, 100)
  local son = false
  if #s.heirs < 6 and RNG.chance(s, 100 + c.favor // 10) then
    son = true
    local h = { name = take_name(s, "male"), age = 0, intel = RNG.range(s, 30, 95),
      mother = c.name, crown = false }
    s.heirs[#s.heirs + 1] = h
    c.son = int(c.son, 0) + 1
    push_log(s, tostring(c.name) .. "诞下皇子" .. h.name .. "。")
  end
  local text = "临幸" .. tostring(c.name) .. "，宠爱 " .. c.favor .. "。"
  if not son then push_log(s, text) end
  return { ok = true, text = text, son = son, heir = son and s.heirs[#s.heirs] or nil }
end
function G.crown(s, idx)
  local h = (s.heirs or {})[int(idx, 0)]
  if type(h) ~= "table" then return { ok = false, text = "无此皇子。" } end
  for _, x in ipairs(s.heirs) do x.crown = false end
  h.crown = true
  G.apply(s, { wei = 1 })
  local text = "立" .. tostring(h.name) .. "为太子。"
  push_log(s, text)
  return { ok = true, text = text }
end

-- ---------- 臣僚 ----------
function G.open_keju(s)
  if s.flags.keju_last == int(s.year, 1) or int(s.res.gold, 0) < 8 then return nil end
  G.apply(s, { gold = -8 })
  s.flags.keju_last = int(s.year, 1)
  local cand = { name = take_name(s, "male"), dept = DEPTS[RNG.range(s, 1, #DEPTS)],
    skill = RNG.range(s, 40, 88), loyalty = RNG.range(s, 45, 85) }
  cand.hint = "才 " .. cand.skill .. " 忠 " .. cand.loyalty .. " · " .. cand.dept .. "部"
  s.flags.keju_candidate = cand
  push_log(s, "开科取士，" .. cand.name .. "擢为" .. cand.dept .. "部观政。")
  return cand
end
function G.appoint(s, cand)
  if type(cand) ~= "table" or type(cand.name) ~= "string" then return { ok = false, text = "此人无名。" } end
  if #s.court >= 9 then return { ok = false, text = "朝列已满。" } end
  local c = { name = cand.name, dept = tostring(cand.dept or "吏"),
    skill = clamp(int(cand.skill, 50), 0, 100), loyalty = clamp(int(cand.loyalty, 50), 0, 100) }
  s.court[#s.court + 1] = c
  local text = "授" .. c.name .. "为" .. c.dept .. "部堂官。"
  push_log(s, text)
  return { ok = true, text = text, court = c }
end
function G.dismiss(s, idx)
  local c = (s.court or {})[int(idx, 0)]
  if type(c) ~= "table" then return { ok = false, text = "无此臣。" } end
  table.remove(s.court, int(idx, 0))
  local text = "罢" .. tostring(c.name) .. "职。"
  push_log(s, text)
  return { ok = true, text = text }
end

-- ---------- 军国 ----------
function G.targets() return ENEMIES end
function G.war(s, target)
  local t
  if type(target) == "table" then t = target
  else for _, x in ipairs(ENEMIES) do if x.name == target or x.id == target then t = x end end end
  if type(t) ~= "table" then return { text = "无此敌国。", win = false } end
  local our = int(s.stats.jun, 0) * 2 + int(s.res.troops, 0) * 3 + int(s.stats.cai, 0) + int(s.res.tech, 0)
  local p = clamp((our * 1000) // (our + math.max(1, int(t.power, 50) * 8)), 50, 900)
  G.apply(s, { gold = -20, grain = -15 })
  local win, text = RNG.chance(s, p), nil
  if win then
    G.apply(s, { troops = -2, wei = 6, min = 2, gold = int(t.loot, 20) })
    text = "王师伐" .. tostring(t.name) .. "，大捷，获银" .. int(t.loot, 20) .. "万贯。"
  else
    G.apply(s, { troops = -6, jun = -8, wei = -4, min = -4, gold = -10 })
    text = "王师伐" .. tostring(t.name) .. "失利，损兵折将。"
  end
  push_log(s, text)
  return { text = text, win = win, chance = p, target = t.name }
end
function G.peace(s)
  G.apply(s, { gold = -20, grain = -10, min = 2, wei = -4, jun = -2 })
  local text = "遣使和亲，输岁币银二十万贯，边尘暂息。"
  push_log(s, text)
  return { ok = true, text = text }
end

-- ---------- 存档 ----------
-- 折子只存展示字段（深度≤5），读档时按 id 从事件数据还原 effect
local function issue_view(e)
  local cs = {}
  for i, c in ipairs(e.choices or {}) do cs[i] = { label = c.label, hint = c.hint } end
  return { id = e.id, tag = e.tag, title = e.title, text = e.text, choices = cs }
end
-- 只读快照：字符串/整数/布尔/表，无函数、无环，可直接 JSON 化（<12KB）
function G.save_view(s)
  return {
    version = 1, year = int(s.year, 1), month = int(s.month, 1), age = int(s.age, 16),
    era = tostring(s.era or "承平"), difficulty = clamp(int(s.difficulty, 1), 1, 3),
    stats = plain(s.stats), res = plain(s.res), health = int(s.health, 0), health_cap = hp_cap(s),
    harem = plain(s.harem), heirs = plain(s.heirs), court = plain(s.court),
    edicts = plain(s.edicts), flags = plain(s.flags), log = plain(s.log),
    rng = int(s.rng, 12345), ended = plain(s.ended), phase = tostring(s.phase or "court"),
    queue = (function()
      local q = {}
      for i, e in ipairs(s.queue or {}) do q[i] = issue_view(e) end
      return q
    end)(), pending = plain(s.pending), month_effects = plain(s.month_effects),
    derived = {
      date_text = date_text(s), tax = tax_of(s), upkeep = upkeep_of(s), grain_in = grain_in_of(s),
      tax_rate = G.tax_rate(s), statline = G.statline(s), court_n = #s.court, heir_n = #s.heirs,
      deficit = { gold = int(s.res.gold, 0) < 0, grain = int(s.res.grain, 0) < 0 },
      alive = s.ended == nil,
    },
  }
end
-- 给 app/store 用：返回纯表（不是 JSON 字符串），编码归 Lead/store
function G.serialize(s) return G.save_view(s) end
-- 从存档表还原：缺字段补默认、数值取整裁剪、折子按 id 还原
function G.deserialize(raw)
  if type(raw) ~= "table" then return G.new() end
  local s = G.new({ difficulty = raw.difficulty, era = raw.era, seed = raw.rng })
  for _, k in ipairs(STATE_KEYS) do if raw[k] ~= nil then s[k] = plain(raw[k]) end end
  s.year = math.max(1, int(s.year, 1))
  s.month = clamp(int(s.month, 1), 1, 12)
  s.age = math.max(1, int(s.age, 16))
  s.difficulty = clamp(int(s.difficulty, 1), 1, 3)
  s.era = type(s.era) == "string" and s.era or "承平"
  s.stats = type(s.stats) == "table" and s.stats or {}
  for _, k in ipairs(STAT_KEYS) do s.stats[k] = clamp(int(s.stats[k], 50), 0, 100) end
  s.res = type(s.res) == "table" and s.res or {}
  for _, k in ipairs(RES_KEYS) do
    local v = int(s.res[k], 0)
    if k == "corr" or k == "tech" then v = clamp(v, 0, 100)
    elseif k == "troops" or k == "pop" then v = math.max(0, v) end
    s.res[k] = v
  end
  for _, k in ipairs({ "harem", "heirs", "court", "queue", "log", "edicts", "month_effects" }) do
    if type(s[k]) ~= "table" then s[k] = {} end
  end
  s.flags = type(s.flags) == "table" and s.flags or {}
  if type(s.flags.recent) ~= "table" then s.flags.recent = {} end
  if type(s.flags.seen) ~= "table" then s.flags.seen = {} end
  s.health = clamp(int(s.health, 90), 0, hp_cap(s))
  s.rng = int(s.rng, 12345) % 2147483648
  if s.rng <= 0 then s.rng = 12345 end
  s.ended = type(s.ended) == "table" and s.ended or nil
  s.phase = s.ended and "over" or (type(s.phase) == "string" and s.phase or "court")
  while #s.log > 12 do table.remove(s.log, 1) end
  local q = {}
  for i, e in ipairs(s.queue) do q[i] = (type(e) == "table" and find_ev(e.id)) or e end
  s.queue = q
  return s
end

-- 别名：index.lua 统一用 G.advance_month 推进一月；文档 §3 名称保留
G.new_game, G.advance_month, G.apply_choice = G.new, G.next_month, G.resolve_issue
return G
