local env = {
    "XDG_CURRENT_DESKTOP,Hyprland",
    "XDG_SESSION_TYPE,wayland",
    "QT_QPA_PLATFORMTHEME,qt6ct",
    "QT_AUTO_SCREEN_SCALE_FACTOR,1",
    "QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
    "ELECTRON_OZONE_PLATFORM_HINT,wayland",
}

local exec_once = {
    "hyprpolkitagent",
    "gnome-keyring-daemon --start --components=secrets",
    "noctalia",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
}

for _, item in ipairs(env) do
    local key, value = item:match("^([^,]+),(.+)$")
    if key and value then
        hl.env(key, value)
    end
end

hl.on("hyprland.start", function()
    for _, command in ipairs(exec_once) do
        hl.exec_cmd(command)
    end
end)

return true