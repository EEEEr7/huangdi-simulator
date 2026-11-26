-- screens/title.lua —— 标题页：大画、年号、难度、开始/继续/帮助
local U = require("ui")
local S = {}

local HINT = "左右 改年号 / 难度　▲▼ 选择　OK 确认"
local ERAS = { "承平", "开元", "永昌" }
local ERA_DESC = {
  "天下初定，府库未丰，正是立规矩的时候。",
  "承前启后，百废待兴，宜先安民而后兴作。",
  "海内晏然，边尘暂息，最难的是守住这份太平。",
}
local DIFFS = { "宽仁", "中庸", "严苛" }
local DIFF_DESC = {
  "赋税轻，民心易得，国库常窘。",
  "赋税平，诸事均衡，最见功夫。",
  "赋税重，国库充盈，民怨易起。",
}

-- 光标：1..3 年号，4..6 难度，7 开始，8 继续，9 帮助
local function cursor_of(V)
  local c = tonumber(V.cursor) or 7
  if c < 1 or c > 9 then c = 7 end
  return c
end

local function era_index(V, gs)
  local i = tonumber(V.era_index)
  if i and i >= 1 and i <= #ERAS then return i end
  for k = 1, #ERAS do
    if ERAS[k] == gs.era then return k end
  end
  return 1
end

local function diff_index(V, gs)
  local i = tonumber(V.diff_index) or tonumber(gs.difficulty)
  if i and i >= 1 and i <= #DIFFS then return i end
  return 2
end

function S.draw(ctx, g, V)
  U.init(ctx)
  g:clear(U.PAPER)
  local hits = {}
  local gs = V.gs or {}
  local cur = cursor_of(V)
  local ei = era_index(V, gs)
  local di = diff_index(V, gs)

  -- 左上角小印
  U.text(g, 32, 22, "XTApp · 横屏墨屏", { size = "small" })

  -- 大画：缺失时 ui 降级为空框 + ？
  U.gray(ctx, g, V, "t_throne", 32, 48, 384, 240)
  U.text(g, 32, 296, U.t(V, "title_scene_cap", "太和殿 · 御门听政"), { size = "small" })
  U.text(g, 32, 320, "在位 " .. tostring(gs.year or 1) .. " 年 · 春秋 " ..
    tostring(gs.age or 16), { size = "small" })
  U.hline(g, 32, 344, 384)
  U.text(g, 32, 356, "御笔亲批，一个月一道折子。", { size = "small", maxw = 384 })
  U.text(g, 32, 378, "国势、民心、健康，任一失守，皆成定局。", { size = "small", maxw = 384 })

  -- 右侧：标题与选择
  local rx, rw = 440, 336
  U.text(g, rx, 50, U.t(V, "game_title", "皇帝成长计划"), { size = "large" })
  U.text(g, rx, 92, U.t(V, "game_sub", "一部冷峻的宫廷账簿"), { size = "small" })
  U.hline(g, rx, 116, rw)

  U.text(g, rx, 130, "年号", { size = "small" })
  for i = 1, #ERAS do
    local bx = rx + (i - 1) * 112
    U.button(g, bx, 148, 104, 28, ERAS[i], { selected = (ei == i), size = "small" })
    U.rowhit(hits, bx, 148, 104, 28, "action", "era:" .. ERAS[i])
  end
  U.text(g, rx, 184, ERA_DESC[ei], { size = "small", maxw = rw })

  U.text(g, rx, 212, "难度", { size = "small" })
  for i = 1, #DIFFS do
    local bx = rx + (i - 1) * 112
    U.button(g, bx, 230, 104, 28, DIFFS[i],
      { selected = (di == i), size = "small" })
    U.rowhit(hits, bx, 230, 104, 28, "action", "difficulty:" .. tostring(i))
  end
  U.text(g, rx, 266, DIFF_DESC[di], { size = "small", maxw = rw })

  local has_save = (V.has_save == true) or (type(V.save) == "table")
  U.button(g, rx, 288, rw, 32, "开始新政", { selected = (cur == 7) })
  U.rowhit(hits, rx, 288, rw, 32, "ok", "start")
  U.button(g, rx, 328, rw, 32, "继续旧档", { selected = (cur == 8), disabled = not has_save })
  if has_save then U.rowhit(hits, rx, 328, rw, 32, "ok", "continue") end
  U.button(g, rx, 368, rw, 32, "御览规例", { selected = (cur == 9) })
  U.rowhit(hits, rx, 368, rw, 32, "action", "help")

  U.text(g, rx, 410, "年号 " .. ERAS[ei] .. " · 难度 " .. DIFFS[di], { size = "small" })
  U.footer(g, U.hint(V, HINT), "v0.1")
  return hits
end

return S
