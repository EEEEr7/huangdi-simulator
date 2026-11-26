-- tools/syntax.lua：语法自检（只 loadfile，不执行）
local root = arg[1] or "project-files"
local bad, n = 0, 0

local function check(path, name)
  local f, err = loadfile(path)
  n = n + 1
  if not f then
    bad = bad + 1
    io.write("ERR  ", name, "\n  ", tostring(err), "\n")
  else
    io.write("OK   ", name, "\n")
  end
end

local function list(dir)
  local out = {}
  local p = io.popen('dir /b "' .. dir .. '" 2>nul')
  if p then
    for line in p:lines() do
      line = line:gsub("[\r\n]+$", "")
      if line ~= "" and line ~= "." and line ~= ".." then out[#out + 1] = line end
    end
    p:close()
  end
  return out
end

check(root .. "/index.lua", "index.lua")
check(root .. "/ui.lua", "ui.lua")

for _, dir in ipairs({ "app", "screens", "lib", "lib/data" }) do
  for _, nm in ipairs(list(root .. "/" .. dir)) do
    if nm:match("%.lua$") then check(root .. "/" .. dir .. "/" .. nm, dir .. "/" .. nm) end
  end
end

io.write(string.format("\n%d files, %d errors\n", n, bad))
os.exit(bad == 0 and 0 or 1)
