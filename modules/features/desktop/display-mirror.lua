-- SUPER + M: mirror one display onto every other one (projector style), or,
-- if anything is mirroring, go back to an extended desktop. The source is the
-- built-in laptop panel when there is one, else the focused monitor.
-- (hyprland.nix; wdisplays can't mirror: wlr-output-management has no mirroring.)

local function is_internal(name)
  return name:match("^eDP") ~= nil or name:match("^LVDS") ~= nil or name:match("^DSI") ~= nil
end

-- Hyprland's default for a monitor without a rule.
local function extend(name)
  hl.monitor({ output = name, mode = "preferred", position = "auto", scale = "auto" })
end

local function toggle_mirror()
  local monitors = hl.get_monitors()

  local mirroring = false
  for _, m in ipairs(monitors) do
    if m.is_mirror then
      mirroring = true
      extend(m.name)
    end
  end
  if mirroring or #monitors < 2 then
    return
  end

  local source = nil
  for _, m in ipairs(monitors) do
    if is_internal(m.name) then
      source = m.name
    end
  end
  if not source then
    for _, m in ipairs(monitors) do
      if m.focused then
        source = m.name
      end
    end
  end

  for _, m in ipairs(monitors) do
    if m.name ~= source then
      hl.monitor({ output = m.name, mode = "preferred", position = "auto", scale = "auto", mirror = source })
    end
  end
end

hl.bind("SUPER + M", toggle_mirror)
