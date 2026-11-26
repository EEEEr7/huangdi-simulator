-- tests/run.lua —— 全部自检：lib/data 内容 + lib/game 月循环
-- 用法（项目根目录）：lua tests/run.lua
package.path = "project-files/?.lua;" .. package.path

local okData, statData = dofile("tests/lib_data.lua")
local okGame, statGame = dofile("tests/lib_game.lua")

print(string.rep("=", 52))
if okData and okGame then
  print("ALL PASS")
  os.exit(0)
else
  print("FAILED")
  os.exit(1)
end
