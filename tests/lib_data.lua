-- tests/lib_data.lua
-- lib/data 数据自校验：字段白名单、字数上限、条数、id 唯一、代价权衡。
-- 独立运行：lua project-files/tests/lib_data.lua
-- 收录用法：local ok, stats = dofile("tests/lib_data.lua")，失败项会打印明细。

local function script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  src = src:gsub("\\", "/")
  return src:match("^(.*)/") or "."
end

local DIR = script_dir()

local function data_path(name)
  local candidates = {
    DIR .. "/../lib/data/" .. name,
    DIR .. "/../../../project-files/lib/data/" .. name,
    "project-files/lib/data/" .. name,
    "lib/data/" .. name,
  }
  for _, p in ipairs(candidates) do
    local f = io.open(p, "rb")
    if f then f:close(); return p end
  end
end

local function load_data(name)
  local path = data_path(name)
  if not path then return nil, "找不到 " .. name end
  local chunk, err = loadfile(path)
  if not chunk then return nil, err end
  local ok, data = pcall(chunk)
  if not ok then return nil, data end
  return data
end

local function clen(s)
  if type(s) ~= "string" then return nil end
  return utf8.len(s) or #s
end

local function is_int(v)
  return type(v) == "number" and v % 1 == 0
end

local EFFECT_KEYS = {
  wang = true, min = true, jun = true, wei = true, cai = true, de = true,
  gold = true, grain = true, troops = true, pop = true, corr = true,
  tech = true, health = true,
}

local SCENES = {
  s_court = true, s_war = true, s_flood = true, s_famine = true,
  s_keju = true, s_banquet = true, s_plague = true, s_prosper = true,
  s_collapse = true, s_treasury = true, s_harem = true, s_hunt = true,
}

local TAGS = { "天灾", "人祸", "边患", "朝争", "后宫", "祥瑞", "奇案", "变法" }

local DECREE_IDS = {
  "keju", "conscript", "relief", "river", "tour", "amnesty",
  "reward_army", "anti_corruption", "fengshan", "school",
  "tuntian", "mint", "market", "luxury_ban", "drill", "grain_buy",
}

local ENDING_NAMES = {
  "盛世", "中兴", "守成", "暴亡", "亡国", "禅让", "被废", "寿终正寝",
}

local total, failed = 0, 0
local module_fails = {}
local current = "?"

local function begin_module(name)
  current = name
  module_fails = {}
end

local function ck(cond, msg)
  total = total + 1
  if not cond then
    failed = failed + 1
    module_fails[#module_fails + 1] = msg
  end
  return cond
end

local function done_module(label, summary)
  local status = (#module_fails == 0) and "OK  " or "FAIL"
  print(string.format("  %-12s %s %s", label, status, summary))
  for _, m in ipairs(module_fails) do
    print("       · " .. m)
  end
  return #module_fails == 0
end

local function check_effects(where, effect)
  if not ck(type(effect) == "table", where .. " effect 须为 table") then return end
  local n = 0
  for k, v in pairs(effect) do
    n = n + 1
    ck(EFFECT_KEYS[k] == true, where .. " 非法 effect key: " .. tostring(k))
    ck(is_int(v), where .. " effect." .. tostring(k) .. " 须为整数")
  end
  ck(n > 0, where .. " effect 不能为空")
end

-- ── events ──
local function check_events()
  begin_module("events")
  local ev, err = load_data("events.lua")
  if not ev then
    ck(false, "载入失败：" .. tostring(err))
    return done_module("events.lua", "载入失败")
  end
  ck(type(ev) == "table", "events 须返回数组")
  if type(ev) ~= "table" then
    return done_module("events.lua", "类型错误")
  end
  ck(#ev >= 40, "事件不少于 40 条，实为 " .. #ev)

  local seen = {}
  local tag_count = {}
  for i, e in ipairs(ev) do
    local where = "events[" .. i .. "]" .. (type(e.id) == "string" and "(" .. e.id .. ")" or "")
    ck(type(e.id) == "string" and e.id:match("^[a-z][a-z0-9_]*$") ~= nil,
      where .. " id 须为英文小写+数字")
    ck(not seen[e.id], where .. " id 重复: " .. tostring(e.id))
    seen[e.id] = true
    ck(type(e.tag) == "string" and SCENES ~= nil, where .. " tag 缺失")
    local known_tag = false
    for _, t in ipairs(TAGS) do
      if e.tag == t then known_tag = true end
    end
    ck(known_tag, where .. " tag 越界: " .. tostring(e.tag))
    tag_count[e.tag] = (tag_count[e.tag] or 0) + 1
    ck(is_int(e.weight) and e.weight > 0, where .. " weight 须为正整数")
    ck(is_int(e.min_year) and e.min_year >= 1, where .. " min_year 须为正整数")
    ck(clen(e.title) ~= nil and clen(e.title) <= 8, where .. " title 不得超过 8 字")
    ck(clen(e.text) ~= nil and clen(e.text) <= 80, where .. " text 不得超过 80 字")
    ck(e.scene == nil or SCENES[e.scene] == true, where .. " scene 越界: " .. tostring(e.scene))

    if ck(type(e.choices) == "table" and #e.choices >= 2 and #e.choices <= 3,
        where .. " 须有 2~3 个选项") then
      for j, ch in ipairs(e.choices) do
        local cw = where .. ".choices[" .. j .. "]"
        ck(clen(ch.label) ~= nil and clen(ch.label) <= 6, cw .. " label 不得超过 6 字")
        ck(clen(ch.hint) ~= nil and clen(ch.hint) <= 14, cw .. " hint 不得超过 14 字")
        check_effects(cw, ch.effect)
        local has_cost = false
        if type(ch.effect) == "table" then
          for _, v in pairs(ch.effect) do
            if is_int(v) and v < 0 then has_cost = true end
          end
        end
        ck(has_cost, cw .. " 无代价（须至少一项负增量）")
      end
    end
  end

  for _, t in ipairs(TAGS) do
    local n = tag_count[t] or 0
    ck(n >= 4 and n <= 6, "tag「" .. t .. "」须 4~6 条，实为 " .. n)
  end
  return done_module("events.lua", #ev .. " 条 / 8 tag 均衡 / id 唯一")
end

-- ── decrees ──
local function check_decrees()
  begin_module("decrees")
  local ds, err = load_data("decrees.lua")
  if not ds then
    ck(false, "载入失败：" .. tostring(err))
    return done_module("decrees.lua", "载入失败")
  end
  ck(type(ds) == "table", "decrees 须返回数组")
  if type(ds) ~= "table" then
    return done_module("decrees.lua", "类型错误")
  end
  ck(#ds == 16, "诏令须 16 条，实为 " .. #ds)

  local seen, found = {}, {}
  for i, d in ipairs(ds) do
    local where = "decrees[" .. i .. "]" .. (type(d.id) == "string" and "(" .. d.id .. ")" or "")
    ck(type(d.id) == "string" and d.id:match("^[a-z][a-z0-9_]*$") ~= nil,
      where .. " id 须为英文小写+数字")
    ck(not seen[d.id], where .. " id 重复: " .. tostring(d.id))
    seen[d.id] = true
    found[d.id] = true
    ck(clen(d.name) ~= nil and clen(d.name) <= 6, where .. " name 不得超过 6 字")
    ck(clen(d.hint) ~= nil and clen(d.hint) <= 16, where .. " hint 不得超过 16 字")

    if ck(type(d.cost) == "table", where .. " cost 须为 table") then
      local cost_ok, positive = true, false
      for k, v in pairs(d.cost) do
        if k ~= "gold" and k ~= "grain" then cost_ok = false end
        if not is_int(v) or v < 0 then cost_ok = false end
        if is_int(v) and v > 0 then positive = true end
      end
      ck(cost_ok, where .. " cost 仅允许 gold/grain 的非负整数")
      ck(positive, where .. " cost 至少一项为正")
    end
    check_effects(where, d.effect)
  end
  for _, id in ipairs(DECREE_IDS) do
    ck(found[id] == true, "缺少诏令: " .. id)
  end
  return done_module("decrees.lua", #ds .. " 条 / 覆盖 16 项")
end

-- ── names ──
local function check_names()
  begin_module("names")
  local ns, err = load_data("names.lua")
  if not ns then
    ck(false, "载入失败：" .. tostring(err))
    return done_module("names.lua", "载入失败")
  end
  local function pool(key, need)
    local list = ns[key]
    ck(type(list) == "table" and #list == need,
      key .. " 须 " .. need .. " 项，实为 " .. tostring(type(list) == "table" and #list or "无"))
    if type(list) ~= "table" then return end
    local s = {}
    for i, v in ipairs(list) do
      ck(type(v) == "string" and clen(v) > 0, key .. "[" .. i .. "] 须为非空字符串")
      ck(not s[v], key .. " 重复: " .. tostring(v))
      s[v] = true
    end
  end
  pool("eras", 20)
  pool("consorts", 24)
  pool("ministers", 40)
  pool("princes", 24)
  pool("enemies", 8)
  pool("surnames", #(ns.surnames or {}))
  ck(type(ns.surnames) == "table" and #ns.surnames >= 20, "surnames 至少 20 项")
  for i, e in ipairs(ns.eras or {}) do
    ck(clen(e) == 2, "eras[" .. i .. "] 须为两字: " .. tostring(e))
  end
  return done_module("names.lua",
    "年号20 后妃24 臣子40 皇子24 敌国8 姓氏" .. tostring(type(ns.surnames) == "table" and #ns.surnames or 0))
end

-- ── texts ──
local function check_texts()
  begin_module("texts")
  local tx, err = load_data("texts.lua")
  if not tx then
    ck(false, "载入失败：" .. tostring(err))
    return done_module("texts.lua", "载入失败")
  end
  ck(type(tx.months) == "table" and #tx.months == 12, "months 须 12 项")
  ck(tx.months and tx.months[1] == "正月" and tx.months[12] == "腊月", "月份须自正月起、至腊月止")
  if type(tx.months) == "table" then
    local s = {}
    for _, m in ipairs(tx.months) do
      ck(not s[m], "月份重复: " .. tostring(m))
      s[m] = true
    end
  end

  local STATS = {
    { "wang", "国势" }, { "min", "民心" }, { "jun", "军心" },
    { "wei", "威望" }, { "cai", "才略" }, { "de", "德行" },
  }
  local RES = {
    { "gold", "银两" }, { "grain", "粮草" }, { "troops", "兵力" },
    { "pop", "人口" }, { "corr", "吏治" }, { "tech", "技术" },
  }
  local function list(key, spec, label)
    local arr = tx[key]
    ck(type(arr) == "table" and #arr == #spec, key .. " 须 " .. #spec .. " 项")
    if type(arr) ~= "table" then return end
    for i = 1, #spec do
      local it = arr[i] or {}
      ck(it.key == spec[i][1] and it.name == spec[i][2],
        label .. "[" .. i .. "] 须为 " .. spec[i][1] .. "/" .. spec[i][2])
    end
  end
  list("stats", STATS, "六维")
  list("res", RES, "资源")

  ck(type(tx.buttons) == "table" and #tx.buttons >= 4, "buttons 至少 4 项")
  ck(type(tx.tips) == "table" and #tx.tips >= 1, "tips 至少 1 项")
  ck(clen(tx.footer) ~= nil and clen(tx.footer) > 0, "footer 缺失")
  ck(clen(tx.help) ~= nil and clen(tx.help) <= 300, "help 不得超过 300 字")

  local RANK_NAMES = { "明君", "中庸", "昏君" }
  ck(type(tx.ranks) == "table" and #tx.ranks == 3, "ranks 须 3 项")
  if type(tx.ranks) == "table" then
    for i, r in ipairs(tx.ranks) do
      ck(r.name == RANK_NAMES[i], "ranks[" .. i .. "] 须为 " .. RANK_NAMES[i])
      ck(clen(r.text) ~= nil and clen(r.text) > 0, "ranks[" .. i .. "] 评语缺失")
    end
  end
  ck(type(tx.rank_map) == "table" and #tx.rank_map == 5, "rank_map 须 5 项")
  if type(tx.rank_map) == "table" then
    for i, name in ipairs(tx.rank_map) do
      ck(name == "明君" or name == "中庸" or name == "昏君",
        "rank_map[" .. i .. "] 越界: " .. tostring(name))
    end
  end
  return done_module("texts.lua",
    "月份12 六维6 资源6 帮助" .. tostring(clen(tx.help) or 0) .. "字")
end

-- ── endings ──
local function check_endings()
  begin_module("endings")
  local es, err = load_data("endings.lua")
  if not es then
    ck(false, "载入失败：" .. tostring(err))
    return done_module("endings.lua", "载入失败")
  end
  ck(type(es) == "table" and #es >= 8, "结局至少 8 个")
  if type(es) ~= "table" then
    return done_module("endings.lua", "类型错误")
  end
  local seen, found = {}, {}
  for i, e in ipairs(es) do
    local where = "endings[" .. i .. "]" .. (type(e.id) == "string" and "(" .. e.id .. ")" or "")
    ck(type(e.id) == "string" and e.id:match("^[a-z][a-z0-9_]*$") ~= nil,
      where .. " id 须为英文小写+数字")
    ck(not seen[e.id], where .. " id 重复: " .. tostring(e.id))
    seen[e.id] = true
    ck(clen(e.name) ~= nil and clen(e.name) > 0, where .. " name 缺失")
    ck(is_int(e.rank) and e.rank >= 1 and e.rank <= 5, where .. " rank 须为 1~5")
    ck(clen(e.text) ~= nil and clen(e.text) <= 120, where .. " text 不得超过 120 字")
    ck(SCENES[e.scene] == true, where .. " scene 越界: " .. tostring(e.scene))
    found[e.name] = true
  end
  for _, name in ipairs(ENDING_NAMES) do
    ck(found[name] == true, "缺少结局: " .. name)
  end
  return done_module("endings.lua", #es .. " 个 / 必备 8 名齐全")
end

print("== lib/data 数据自校验 ==")
local passed = 0
if check_events() then passed = passed + 1 end
if check_decrees() then passed = passed + 1 end
if check_names() then passed = passed + 1 end
if check_texts() then passed = passed + 1 end
if check_endings() then passed = passed + 1 end

print(string.rep("-", 48))
local ok = failed == 0
if ok then
  print(string.format("全绿：%d/5 文件，%d 项检查全部通过", passed, total))
else
  print(string.format("未通过：%d/5 文件，%d 项失败（共 %d 项检查）", passed, failed, total))
end

return ok, { files = passed, checks = total, failed = failed }
