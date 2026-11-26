-- screens/help.lua —— 御览规例：操作、数值、月流程、结局
local U = require("ui")
local S = {}

local HINT = "BACK 返回　点按「返回」亦可"

-- 每行不超过 11 个汉字（240px 内不折行）
local LEFT = {
  { "操作", "上下移光标，中间键确认" },
  { "", "触屏可直接点按" },
  { "", "返回键离屏，标题页退出" },
  { "月流程", "一月一道折子，批红后进" },
  { "", "月末结算税银、粮草" },
  { "", "九、十月秋收，粮入加倍" },
}
local MID = {
  { "六维", "国势 民心 军心" },
  { "", "威望 才略 德行" },
  { "", "任一维归零即结局" },
  { "国用", "银、粮可透支" },
  { "", "赤字伤民心、军心" },
  { "健康", "每月耗损，六十下调养" },
}
local RIGHT = {
  { "诏令", "十六道，每月一道" },
  { "", "立即生效" },
  { "后宫", "选秀添人，临幸得嗣" },
  { "", "立储可续国祚" },
  { "军国", "征伐耗银粮" },
  { "", "和亲岁币，戍边耗粮" },
}

local function column(g, x, y, w, rows)
  local cy = y
  for i = 1, #rows do
    local r = rows[i]
    if r[1] ~= "" then
      U.text(g, x, cy, r[1], { size = "medium", maxw = 246 })
      cy = cy + 24
    end
    U.text(g, x, cy, r[2], { size = "small", maxw = 246 })
    cy = cy + 24
  end
  return cy
end

function S.draw(ctx, g, V)
  local hits = U.page(ctx, g, V, {
    header = true, sidebar = false, tabs = false, hint = HINT, right = "规例",
  })
  U.text(g, 24, 52, "御览规例", { size = "medium", maxw = 300 })
  U.hline(g, 24, 74, 752)
  U.section(g, 24, 86, 246, "朝仪")
  U.section(g, 280, 86, 246, "身国")
  U.section(g, 536, 86, 246, "政务")
  column(g, 24, 110, 240, LEFT)
  column(g, 280, 110, 240, MID)
  column(g, 536, 110, 240, RIGHT)
  U.hline(g, 24, 380, 752)
  U.text(g, 24, 392, "天下之事，在一念之间。批红易，收局难。", { size = "small", maxw = 560 })
  U.button(g, 648, 386, 128, 32, "返回", {})
  U.rowhit(hits, 648, 386, 128, 32, "action", "back")
  return hits
end

return S
