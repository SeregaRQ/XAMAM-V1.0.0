-- Main.lua — main loader for Delta
-- This file loads GUI.lua and other scripts in the same directory.

local function get_script_dir()
  local info = debug.getinfo(1, "S").source
  if info:sub(1,1) == '@' then info = info:sub(2) end
  return info:match("(.*/)") or "./"
end

local script_dir = get_script_dir()

-- Load GUI.lua and print confirmation on success
local gui_path = script_dir .. "GUI.lua"
local ok, err = pcall(function() dofile(gui_path) end)
if ok then
  print("GUI loaded")
else
  io.stderr:write("Failed to load GUI.lua: " .. tostring(err) .. "\n")
end

-- Attempt to load other .lua files in the same directory (excluding Main.lua and GUI.lua) if lfs is available
local function load_other_scripts()
  local ok_lfs, lfs = pcall(require, "lfs")
  if not ok_lfs then
    -- lfs not available; nothing else to do
    return
  end

  for file in lfs.dir(script_dir) do
    if file:match("%.lua$") and file ~= "Main.lua" and file ~= "GUI.lua" then
      local path = script_dir .. file
      local s, e = pcall(function() dofile(path) end)
      if not s then
        io.stderr:write(string.format("Failed to load %s: %s\n", file, tostring(e)))
      else
        print(string.format("Loaded %s", file))
      end
    end
  end
end

pcall(load_other_scripts)
