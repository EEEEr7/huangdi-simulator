-- app/assets.lua —— 包内图像加载与绘制（Lead）
-- 约定：portrait 等比 contain 居中；scene 等比 cover 居中裁切；
-- gray_scene 用 4 阶静态图（会触发一次整帧灰阶刷新，只给标题/结局这类静止画面）。
-- screens 通过 V.A 调用，不直接 require 本模块。

local A = {}
local cache = {}
local GRAY = { t_throne = true, e_end = true }
local MISSING = false

function A.reset()
  cache = {}
end

-- 加载并缓存；缺图返回 nil，不抛错（包内 asset 名或 api 差异都不该弄崩界面）
local function load(ctx, key)
  if type(key) ~= "string" or key == "" then return nil end
  local v = cache[key]
  if v ~= nil then return v or nil end
  local ok, im = pcall(ctx.package.image, ctx.package, key)
  if not ok or im == nil then
    cache[key] = MISSING
    return nil
  end
  cache[key] = im
  return im
end

function A.has(ctx, key)
  return load(ctx, key) ~= nil
end

local function box(g, x, y, w, h)
  if not w or not h or w < 1 or h < 1 then return end
  g:rect(x, y, w, h, { line_width = 2 })
  g:line(x, y, x + w - 1, y + h - 1, { line_width = 1 })
  g:line(x + w - 1, y, x, y + h - 1, { line_width = 1 })
end

local function dims(im)
  local ok, iw, ih = pcall(function() return im.width, im.height end)
  iw, ih = tonumber(iw) or 0, tonumber(ih) or 0
  if ok and iw >= 1 and ih >= 1 then return iw, ih end
  return nil, nil
end

-- contain：整图放进 w×h，留白居中
function A.portrait(ctx, g, key, x, y, w, h)
  local im = load(ctx, key)
  local iw, ih
  if im then iw, ih = dims(im) end
  if not iw or not ih then
    box(g, x, y, w, h); return false
  end
  local dw, dh
  if iw * h > ih * w then
    dw, dh = w, math.max(1, math.floor(ih * w / iw))
  else
    dh, dw = h, math.max(1, math.floor(iw * h / ih))
  end
  local dx, dy = x + (w - dw) // 2, y + (h - dh) // 2
  g:image(im, dx, dy, { w = dw, h = dh })
  return true
end

-- 等比裁切到目标比例，再用 src 取源图中心块，精确铺满 w×h
local function cover(ctx, g, key, x, y, w, h, gray)
  local im = load(ctx, key)
  local iw, ih
  if im then iw, ih = dims(im) end
  if not iw or not ih then box(g, x, y, w, h); return false end
  local cw, ch = iw, ih
  if iw * h > ih * w then
    cw = math.max(1, math.floor(ih * w / h))
  elseif iw * h < ih * w then
    ch = math.max(1, math.floor(iw * h / w))
  end
  local sx, sy = (iw - cw) // 2, (ih - ch) // 2
  local opts = { w = w, h = h, src = { x = sx, y = sy, w = cw, h = ch } }
  if gray then opts.gray = true end
  local ok = pcall(g.image, g, im, x, y, opts)
  if not ok then
    -- 低版本没有 src：退化为整图缩放（可能轻微变形，但不崩）
    if not pcall(g.image, g, im, x, y, { w = w, h = h }) then
      g:image(im, x, y)
    end
  end
  return true
end

function A.scene(ctx, g, key, x, y, w, h)
  return cover(ctx, g, key, x, y, w, h, false)
end

function A.gray_scene(ctx, g, key, x, y, w, h)
  return cover(ctx, g, key, x, y, w, h, GRAY[key] == true)
end

function A.icon(ctx, g, key, x, y, s)
  local im = load(ctx, key)
  local iw, ih
  if im then iw, ih = dims(im) end
  s = s or 24
  if not iw then
    g:rect(x, y, s, s, { line_width = 1 })
    return false
  end
  g:image(im, x + (s - math.min(s, iw)) // 2, y + (s - math.min(s, ih)) // 2, { w = s, h = s })
  return true
end

return A
