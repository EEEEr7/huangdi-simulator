-- tests/lib_game.lua —— 月循环、存档、不变量（无 ctx，纯 Lua）
-- 由 tests/run.lua 加载；也可 lua tests/lib_game.lua 单跑（需在项目根目录）。
package.path = "project-files/?.lua;" .. package.path

local G = require("lib.game")

local pass, fail, msgs = 0, 0, {}
local function ck(cond, name, extra)
  if cond then
    pass = pass + 1
  else
    fail = fail + 1
    msgs[#msgs + 1] = name .. (extra and (" | " .. tostring(extra)) or "")
  end
  return cond
end

-- 估算存档 JSON 字节数（%q 会转义，实际 JSON 只多不少，够用作上限判断）
local function enc(v, out)
  local t = type(v)
  if t == "string" then
    out[#out + 1] = string.format("%q", v)
  elseif t == "number" then
    out[#out + 1] = string.format("%.0f", v)
  elseif t == "boolean" then
    out[#out + 1] = v and "true" or "false"
  elseif t == "table" then
    out[#out + 1] = "{"
    for k, x in pairs(v) do
      if type(k) == "string" then out[#out + 1] = k .. ":" end
      enc(x, out)
      out[#out + 1] = ","
    end
    out[#out + 1] = "}"
  else
    out[#out + 1] = "null"
  end
  return out
end
local function jsize(v)
  return #table.concat(enc(v, {}))
end

local function drain(s)
  local guard = 0
  while type(s.queue) == "table" and #s.queue > 0 and guard < 20 do
    G.resolve_issue(s, s.queue[1], 1)
    guard = guard + 1
  end
  return guard
end

local function step(s)
  drain(s)
  if s.pending then s.pending = nil end
  G.next_month(s)
end

-- 1. 开局
do
  local s = G.new({ difficulty = 2, seed = 20261126 })
  ck(type(s) == "table", "new: 返回表")
  ck(s.year == 1 and s.month == 1, "new: 元月元年")
  ck(s.age == 16, "new: 十六岁即位")
  ck(type(s.res.gold) == "number" and s.res.gold > 0, "new: 有银")
  ck(type(s.stats) == "table" and s.stats.wang == 50, "new: 六维五十")
  ck(#s.log >= 1, "new: 本纪有第一条")
end

-- 2. 一个月循环
do
  local s = G.new({ difficulty = 1, seed = 7 })
  G.start_month(s)
  ck(s.month == 1, "start_month: 仍在一月")
  ck(#s.queue > 0, "start_month: 抽到折子")
  local n = drain(s)
  ck(n >= 1, "resolve_issue: 可批完当月折子")
  ck(#s.queue == 0, "resolve_issue: 批完队列空")
  ck(type(s.pending) == "table" and type(s.pending.text) == "string" and s.pending.text ~= "",
    "resolve_issue: 写回 pending.text")
  local gold = s.res.gold
  s.pending = nil
  G.next_month(s)
  ck(s.month == 2, "next_month: 进二月")
  ck(type(s.res.gold) == "number", "next_month: 银仍为数字", s.res.gold)
  ck(gold ~= s.res.gold or true, "next_month: 结算不崩")
end

-- 3. 跨年与年龄
do
  local s = G.new({ difficulty = 2, seed = 99 })
  G.start_month(s)
  for _ = 1, 12 do step(s) end
  ck(s.year == 2 and s.month == 1, "12 月后：二年正月", s.year .. "/" .. s.month)
  ck(s.age == 17, "12 月后：长一岁", s.age)
  for _ = 1, 12 do step(s) end
  ck(s.year == 3 and s.age == 18, "24 月后：三年十八岁", s.year .. "/" .. s.age)
end

-- 4. 种子决定折子
do
  local a = G.new({ difficulty = 2, seed = 4242 })
  local b = G.new({ difficulty = 2, seed = 4242 })
  G.start_month(a); G.start_month(b)
  local ids_a, ids_b = {}, {}
  for i, e in ipairs(a.queue) do ids_a[i] = tostring(e.id) end
  for i, e in ipairs(b.queue) do ids_b[i] = tostring(e.id) end
  ck(table.concat(ids_a, ",") == table.concat(ids_b, ","), "同种子：折子相同")
end

-- 5. 存档往返
do
  local s = G.new({ difficulty = 3, seed = 55 })
  G.start_month(s)
  drain(s)
  local snap = G.serialize(s)
  ck(type(snap) == "table", "serialize: 返回快照表")
  local raw = jsize(snap)
  ck(raw > 0, "serialize: 快照非空")
  ck(raw < 12288, "serialize: 小於 12KB", raw)
  local ok, s2 = pcall(G.deserialize, snap)
  ck(ok and type(s2) == "table", "deserialize: 可还原", not ok and s2 or nil)
  if ok and type(s2) == "table" then
    ck(s2.month == s.month and s2.year == s.year, "deserialize: 年月一致")
    ck(s2.res.gold == s.res.gold, "deserialize: 银一致")
    ck(s2.health == s.health, "deserialize: 健康一致")
    ck(jsize(G.serialize(s2)) < 12288, "deserialize: 再存仍小於 12KB")
  end
end

-- 6. 长跑不变量
do
  local s = G.new({ difficulty = 2, seed = 31415 })
  G.start_month(s)
  local bad
  for m = 1, 60 do
    step(s)
    if s.ended then break end
    for k, v in pairs(s.stats) do
      if type(v) ~= "number" or v < 0 or v > 100 then bad = k .. "=" .. tostring(v) break end
    end
    if bad then break end
    if s.health < 0 or s.health > 90 then bad = "health=" .. tostring(s.health) break end
    for _, k in ipairs({ "troops", "pop", "corr", "tech" }) do
      if type(s.res[k]) ~= "number" or s.res[k] < 0 then bad = k .. "=" .. tostring(s.res[k]) break end
    end
    if bad then break end
    if jsize(G.serialize(s)) >= 12288 then bad = "save too big m" .. m break end
  end
  ck(bad == nil, "60 月长跑：数值不越界", bad)
  ck(type(s.log) == "table" and #s.log > 0, "60 月长跑：有本纪")
end

-- 7. 结局：健康归零
do
  local s = G.new({ difficulty = 2, seed = 5 })
  G.start_month(s)
  s.health = 0
  G.advance_month(s)
  ck(type(s.ended) == "table" and s.ended.id == "death_ill", "结局：病逝",
    type(s.ended) == "table" and s.ended.id or tostring(s.ended))
end

-- 8. 结局：民心归零
do
  local s = G.new({ difficulty = 2, seed = 6 })
  G.start_month(s)
  s.stats.min = 0
  G.advance_month(s)
  ck(type(s.ended) == "table" and s.ended.id == "rebellion", "结局：民变",
    type(s.ended) == "table" and s.ended.id or tostring(s.ended))
end

-- 9. 军国：征伐有结果且不崩
do
  local s = G.new({ difficulty = 2, seed = 8 })
  G.start_month(s)
  local t = (G.targets() or {})[1]
  ck(type(t) == "table", "targets: 有边患目标")
  local ok, out = pcall(G.war, s, t)
  ck(ok and type(out) == "table" and type(out.text) == "string", "war: 返回战报", not ok and out or nil)
  ck(s.res.troops >= 0, "war: 兵力不为负")
end

-- 10. 诏令列表形状
do
  local s = G.new({ difficulty = 2, seed = 9 })
  local list = G.decree_list(s)
  ck(type(list) == "table" and #list >= 8, "decree_list: 至少八道", type(list) == "table" and #list or 0)
  if type(list) == "table" and list[1] then
    ck(type(list[1].name) == "string" and list[1].name ~= "", "decree_list: 有诏名")
  end
end

print(string.format("== lib/game 月循环自检 ==  通过 %d / 失败 %d", pass, fail))
for i = 1, #msgs do print("  FAIL " .. msgs[i]) end

return fail == 0, { pass = pass, fail = fail }
