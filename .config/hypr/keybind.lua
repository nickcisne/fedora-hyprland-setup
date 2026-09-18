local main_mod = "SUPER"
local home = os.getenv("HOME") or ""
local screenshot_dir = home .. "/Pictures/Screenshots"

local function command(command_text)
    return hl.dsp.exec_cmd(command_text)
end

hl.bind(main_mod .. " + RETURN", command("kitty"), { description = "Terminal" })
hl.bind(main_mod .. " + E", command("thunar"), { description = "File manager" })
hl.bind(main_mod .. " + C", command("code"), { description = "Code editor" })
hl.bind(main_mod .. " + B", command("chromium"), { description = "Browser" })
hl.bind(main_mod .. " + D", command("noctalia msg panel-toggle launcher"), { description = "Application launcher" })
hl.bind(main_mod .. " + T", command("noctalia msg settings-toggle"), { description = "Noctalia settings" })
hl.bind(main_mod .. " + L", command("noctalia msg session lock"), { description = "Lock screen" })
hl.bind(main_mod .. " + V", command("cliphist list | wofi --dmenu | cliphist decode | wl-copy"), { description = "Clipboard history" })

hl.bind(main_mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(main_mod .. " + W", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind("ALT + tab", hl.dsp.window.cycle_next(), { description = "Cycle windows" })

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })

hl.bind(main_mod .. " + SHIFT + right", command("hyprctl dispatch resizeactive 30 0"), { description = "Resize right" })
hl.bind(main_mod .. " + SHIFT + left", command("hyprctl dispatch resizeactive -30 0"), { description = "Resize left" })
hl.bind(main_mod .. " + SHIFT + up", command("hyprctl dispatch resizeactive 0 -30"), { description = "Resize up" })
hl.bind(main_mod .. " + SHIFT + down", command("hyprctl dispatch resizeactive 0 30"), { description = "Resize down" })

hl.bind(main_mod .. " + PRINT", command("mkdir -p " .. screenshot_dir .. " && grim -g \"$(slurp)\" " .. screenshot_dir .. "/Screenshot-$(date +%Y%m%d-%H%M%S).png"), { description = "Screenshot region" })
hl.bind("ALT + PRINT", command("mkdir -p " .. screenshot_dir .. " && grim " .. screenshot_dir .. "/Screenshot-$(date +%Y%m%d-%H%M%S).png"), { description = "Screenshot display" })
hl.bind("SHIFT + PRINT", command("grim -g \"$(slurp)\" - | wl-copy"), { description = "Copy screenshot region" })

for workspace = 1, 9 do
    hl.bind(main_mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }), { description = "Workspace " .. workspace })
    hl.bind(main_mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }), { description = "Move to workspace " .. workspace })
end

hl.bind(main_mod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "Workspace 10" })
hl.bind(main_mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }), { description = "Move to workspace 10" })
hl.bind(main_mod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }), { description = "Next workspace" })
hl.bind(main_mod .. " + CTRL + left", hl.dsp.focus({ workspace = "r-1" }), { description = "Previous workspace" })
hl.bind(main_mod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }), { description = "Empty workspace" })

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

hl.bind("XF86AudioPlay", command("playerctl play-pause"), { locked = true, description = "Play or pause" })
hl.bind("XF86AudioNext", command("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", command("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioRaiseVolume", command("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", command("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, description = "Volume down" })

return true