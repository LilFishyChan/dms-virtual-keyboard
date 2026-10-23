.pragma library

// Shared shortcut-function catalog and helpers, used by the fixed row and the
// all-functions list page.
//
// "cmd" (optional) is argv for a process to run when the function is triggered;
// functions without a cmd (drag/float/pin/resize) are handled internally.
var defs = [
    // --- local keyboard functions ---
    { id: "drag", label: "Drag", icon: "open_with" },
    { id: "float", label: "Float", icon: "picture_in_picture_alt", labelAlt: "Dock", iconAlt: "dock_to_bottom" },
    { id: "pin", label: "Pin", icon: "keep", labelAlt: "Overlay", iconAlt: "keep_off" },
    { id: "resize", label: "Resize", icon: "aspect_ratio" },

    // --- DMS common ---
    { id: "clipboard", label: "Clipboard (dms)", icon: "content_paste", cmd: ["dms", "ipc", "call", "clipboard", "toggle"] },
    { id: "dms-cc", label: "Control Center (dms)", icon: "tune", cmd: ["dms", "ipc", "call", "control-center", "toggle"] },
    { id: "dms-launcher", label: "Launcher (dms)", icon: "apps", cmd: ["dms", "ipc", "call", "launcher", "toggle"] },
    { id: "dms-dash", label: "Dash (dms)", icon: "widgets", cmd: ["dms", "ipc", "call", "dash", "toggle"] },
    { id: "dms-vol-up", label: "Volume + (dms)", icon: "volume_up", cmd: ["dms", "ipc", "call", "audio", "increment", "5"] },
    { id: "dms-vol-down", label: "Volume - (dms)", icon: "volume_down", cmd: ["dms", "ipc", "call", "audio", "decrement", "5"] },
    { id: "dms-mute", label: "Mute (dms)", icon: "volume_off", cmd: ["dms", "ipc", "call", "audio", "mute"] },
    { id: "dms-bri-up", label: "Brightness + (dms)", icon: "brightness_high", cmd: ["dms", "ipc", "call", "brightness", "increment", "5"] },
    { id: "dms-bri-down", label: "Brightness - (dms)", icon: "brightness_low", cmd: ["dms", "ipc", "call", "brightness", "decrement", "5"] }
]

function ids() {
    var out = []
    for (var i = 0; i < defs.length; i++)
        out.push(defs[i].id)
    return out
}

function info(id, floating, avoidEnabled) {
    for (var i = 0; i < defs.length; i++) {
        var d = defs[i]
        if (d.id !== id)
            continue
        if (id === "float")
            return { label: floating ? d.labelAlt : d.label, icon: floating ? d.iconAlt : d.icon }
        if (id === "pin")
            return { label: avoidEnabled ? d.label : d.labelAlt, icon: avoidEnabled ? d.icon : d.iconAlt }
        return { label: d.label, icon: d.icon }
    }
    return { label: "", icon: "" }
}

// argv for the process to run for this function, or null if handled internally.
function cmdFor(id) {
    for (var i = 0; i < defs.length; i++) {
        if (defs[i].id === id && defs[i].cmd)
            return defs[i].cmd
    }
    return null
}

// A function is disabled when it does nothing in the current mode.
// Dragging only makes sense while floating (docked is anchored at the bottom).
function isDisabled(id, floating) {
    if (id === "drag")
        return !floating
    if (id === "pin")
        return floating
    return false
}

// A function is active when its state is "on" (highlighted border).
function isActive(id, floating, avoidEnabled, resizing, opacity) {
    if (id === "pin")
        return avoidEnabled && !floating
    if (id === "resize")
        return !!resizing
    if (id === "opacity")
        return opacity < 0.999
    return false
}
