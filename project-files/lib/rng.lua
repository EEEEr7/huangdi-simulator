-- lib/rng.lua：可重放的线性同余随机数（纯 Lua、纯整数、无 ctx）
-- 用法：state.rng 存种子，每次抽取原地写回，因此同一 state 序列可完整重放。
-- 概率一律用千分比整数，例如 RNG.chance(state, 300) = 30%。
local RNG = {}

local M = 2147483648 -- 2^31，模数
local A = 1103515245
local C = 12345
local DEFAULT_SEED = 12345

-- 把任意输入规整成 [1, M-1] 的整数种子
local function norm(n)
  n = math.floor(tonumber(n) or DEFAULT_SEED) % M
  if n <= 0 then n = n + M end
  return n
end

function RNG.set(state, seed)
  state.rng = norm(seed)
  return state.rng
end

function RNG.next(state)
  if type(state) ~= "table" then
    error("RNG.next: state 必须是表", 2)
  end
  local r = norm(state.rng)
  r = (A * r + C) % M -- 64 位 Lua 下 1103515245 * (2^31-1) 不溢出
  state.rng = r
  return r
end

-- perMille ∈ [0, 1000]，返回布尔；<=0 必假，>=1000 必真
function RNG.chance(state, perMille)
  local p = math.floor(tonumber(perMille) or 0)
  local roll = RNG.next(state) % 1000
  return roll < p
end

-- 闭区间整数 [a, b]
function RNG.range(state, a, b)
  a = math.floor(tonumber(a) or 0)
  b = math.floor(tonumber(b) or 0)
  if b < a then a, b = b, a end
  return a + RNG.next(state) % (b - a + 1)
end

function RNG.pick(state, list)
  if type(list) ~= "table" or #list == 0 then return nil end
  return list[RNG.range(state, 1, #list)]
end

-- 原地洗牌（Fisher-Yates），返回同一表
function RNG.shuffle(state, list)
  if type(list) ~= "table" then return list end
  for i = #list, 2, -1 do
    local j = RNG.range(state, 1, i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end

return RNG
