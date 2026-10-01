-- Laptop lid handling for Hyprland (homeManager.laptop, laptop.nix).
--
-- Lid closed, another monitor connected: disable the built-in panel, so
--   Hyprland moves its workspaces to the remaining monitors.
-- Lid closed, no other monitor: lock the session and turn the panel off.
-- Lid opened: re-enable the panel and turn displays back on.
-- Also: starting (or reloading) with the lid closed while docked, plugging a
-- monitor in with the lid closed, and unplugging the last external monitor
-- with the lid closed (the panel comes back, locked and off).
--
-- logind ignores the lid (nixos.laptop), so nothing suspends here.

local function is_internal(name)
  return name:match("^eDP") ~= nil or name:match("^LVDS") ~= nil or name:match("^DSI") ~= nil
end

-- hl.get_monitors() only lists active monitors, so the panel's name is
-- remembered for re-enabling it.
local internal = nil
local panel_disabled = false

-- Number of active monitors other than the panel (and learns its name).
local function externals()
  local n = 0
  for _, m in ipairs(hl.get_monitors()) do
    if is_internal(m.name) then
      internal = m.name
    else
      n = n + 1
    end
  end
  return n
end

local function lid_closed()
  local dir = io.popen("ls /proc/acpi/button/lid 2>/dev/null")
  if not dir then
    return false
  end
  local closed = false
  for entry in dir:lines() do
    local f = io.open("/proc/acpi/button/lid/" .. entry .. "/state")
    if f then
      closed = closed or (f:read("a") or ""):find("closed") ~= nil
      f:close()
    end
  end
  dir:close()
  return closed
end

-- Hyprland re-lays out every monitor when one is disabled or enabled, but only
-- re-places the layer surfaces (wallpaper, bar) of monitors whose rule
-- changed: the others' would stay at their old position, shifted. So their
-- rules change too: pinned where they are while the panel is off (nothing
-- moves), back to auto when it returns.
local function others()
  local list = {}
  for _, m in ipairs(hl.get_monitors()) do
    if not is_internal(m.name) then
      list[#list + 1] = m
    end
  end
  return list
end

local function disable_panel()
  if internal and not panel_disabled then
    for _, m in ipairs(others()) do
      hl.monitor({ output = m.name, position = m.x .. "x" .. m.y })
    end
    hl.monitor({ output = internal, disabled = true })
    panel_disabled = true
  end
end

-- The panel returns at 0x0: explicit positions are placed before auto ones,
-- so the others go back to its right, as when the session started.
-- hl.monitor updates an output's rule field by field, so `disabled` is reset.
local function enable_panel()
  if internal and panel_disabled then
    hl.monitor({ output = internal, disabled = false, mode = "preferred", position = "0x0", scale = "auto" })
    for _, m in ipairs(others()) do
      hl.monitor({ output = m.name, position = "auto" })
    end
    panel_disabled = false
  end
end

local function lock_and_blank()
  hl.exec_cmd("loginctl lock-session")
  hl.dispatch(hl.dsp.dpms({ action = "off" }))
end

hl.bind("switch:on:Lid Switch", function()
  if externals() > 0 then
    disable_panel()
  else
    lock_and_blank()
  end
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
  enable_panel()
  hl.dispatch(hl.dsp.dpms({ action = "on" }))
end, { locked = true })

-- Docking with the lid closed (also at login, as monitors appear).
hl.on("monitor.added", function()
  if externals() > 0 and lid_closed() then
    disable_panel()
  end
end)

-- The last external monitor went away with the lid closed: Hyprland must not
-- be left without a monitor, so bring the panel back, locked; it is turned
-- off once it is active again.
hl.on("monitor.removed", function()
  if panel_disabled and externals() == 0 then
    enable_panel()
    hl.exec_cmd("loginctl lock-session")
    hl.timer(function()
      if lid_closed() then
        hl.dispatch(hl.dsp.dpms({ action = "off" }))
      end
    end, { timeout = 1000, type = "oneshot" })
  end
end)

-- A config reload drops the runtime rule that disabled the panel.
if externals() > 0 and lid_closed() then
  disable_panel()
end
