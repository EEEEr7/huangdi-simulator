-- app/store.lua —— 存档（ctx.state.game 只放 G.save_view 的快照，≤16KB/深度 6）
-- 自动存档由宿主负责（ctx.state 变化即写卡）；这里在关键节点主动 ctx:save_state()。
local Store = {}
local G = require("lib.game")
local KEY = "game"

function Store.has(ctx)
  local st = ctx and ctx.state
  return type(st) == "table" and type(st[KEY]) == "table"
end

-- 读档；坏档/旧档一律返回 nil（调用方回标题页），绝不抛错
function Store.load(ctx)
  local st = ctx and ctx.state
  if type(st) ~= "table" then return nil end
  local raw = st[KEY]
  if type(raw) ~= "table" then return nil end
  local ok, gs = pcall(G.deserialize, raw)
  if ok and type(gs) == "table" then return gs end
  st[KEY] = nil
  return nil
end

function Store.save(ctx, gs)
  if type(ctx) ~= "table" or type(gs) ~= "table" then return false end
  local ok, snap = pcall(G.serialize, gs)
  if not ok or type(snap) ~= "table" then return false end
  ctx.state = type(ctx.state) == "table" and ctx.state or {}
  ctx.state[KEY] = snap
  if type(ctx.save_state) == "function" then pcall(ctx.save_state, ctx) end
  return true
end

function Store.clear(ctx)
  local st = ctx and ctx.state
  if type(st) == "table" then st[KEY] = nil end
  if type(ctx) == "table" and type(ctx.save_state) == "function" then pcall(ctx.save_state, ctx) end
end

return Store
