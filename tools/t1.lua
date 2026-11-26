package.path = "project-files/?.lua;project-files/?/init.lua;" .. package.path
local G = require("lib.game")
local s = G.new({ difficulty = 2, seed = 7 })
G.start_month(s)
print("start", s.res.gold, s.res.grain, s.res.pop, s.stats.min)
local ev = s.queue[1]
if ev then
  G.resolve_issue(s, ev, 1)
  G.next_month(s)
end
print("after month", s.month, s.res.gold, s.res.grain)
for k, v in pairs(s.month_effects or {}) do print("fx", k, v) end
print("flags.monthly", s.flags.monthly and s.flags.monthly.tax, s.flags.monthly and s.flags.monthly.upkeep, s.flags.monthly and s.flags.monthly.grain_in)
print("save bytes", #G.serialize(s))
