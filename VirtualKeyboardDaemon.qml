import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Which window the keyboard uses: docked to the bottom edge (PanelWindow
    // anchored bottom) or floating/movable (an unanchored PanelWindow). Both
    // are layer-shell surfaces with keyboardFocus None, so neither steals the
    // keyboard focus nor makes ydotool's injected keys land on the keyboard.
    property bool pinned: false
    // Toggled by the keyboard's pin button: whether the docked keyboard reserves
    // space at the bottom (windows avoid it) or overlays windows.
    property bool avoidWindows: true
    // Fixed shortcut row contents, persisted through the plugin data API so
    // they survive closing the keyboard and restarting the shell.
    property var fixedItems: ["drag", "float", "pin"]
    // Uniform user scale set by the resize function (persisted below). Exposed
    // as a plain property so the windows' bindings definitely track it.
    property real userScale: ydotoolService.userScale

    Component.onCompleted: {
        const stored = PluginService.loadPluginData(root.pluginId, "fixedItems", null)
        if (stored && stored.length !== undefined)
            root.fixedItems = stored
        const sc = PluginService.loadPluginData(root.pluginId, "userScale", 1)
        if (sc && sc > 0)
            ydotoolService.userScale = sc
        root.applyOpacity()
    }

    // Opacity is owned by ydotool (the card binds to it) and mirrored to the
    // "opacity" plugin setting (30-100) so the settings slider works both ways.
    function applyOpacity() {
        const v = Number(PluginService.loadPluginData(root.pluginId, "opacity", 100))
        const o = Math.max(0.3, Math.min(1, (v > 0 ? v : 100) / 100))
        if (Math.abs(ydotoolService.keyboardOpacity - o) > 0.002)
            ydotoolService.keyboardOpacity = o
    }

    // Persist the uniform user scale set by the resize function.
    Connections {
        target: ydotoolService
        function onUserScaleChanged() {
            PluginService.savePluginData(root.pluginId, "userScale", ydotoolService.userScale)
        }
        function onKeyboardOpacityChanged() {
            PluginService.savePluginData(root.pluginId, "opacity", Math.round(ydotoolService.keyboardOpacity * 100))
        }
    }

    // Pick up opacity changes made from the settings slider.
    Connections {
        target: PluginService
        function onPluginDataChanged(pluginId) {
            if (pluginId === root.pluginId)
                root.applyOpacity()
        }
    }

    function setFixedItems(items) {
        root.fixedItems = items
        PluginService.savePluginData(root.pluginId, "fixedItems", items)
    }
    readonly property bool keyboardOpen: (dockedLoader.item && dockedLoader.item.keyboardVisible) || (floatingLoader.item && floatingLoader.item.keyboardVisible)

    // Not named `ydotool`: see the comment below on why that collides with
    // a same-named property being initialized on the windows that consume
    // it, silently breaking every level of the hand-off.
    Ydotool {
        id: ydotoolService
    }

    // `active`, not `loading`: `loading` only starts a background load and
    // does nothing once the item exists, so it can never take a window back
    // down. `active` is the property that creates and destroys the item, and
    // it loads synchronously, which openKeyboard() relies on when it touches
    // `item` on the line right after.
    LazyLoader {
        id: dockedLoader
        active: false

        KeyboardWindow {
            ydotool: ydotoolService
            avoidWindows: root.avoidWindows
            fixedItems: root.fixedItems
            userScale: root.userScale
            onFixedItemsEdited: items => root.setFixedItems(items)
            onPinRequested: root.avoidWindows = !root.avoidWindows
            onFloatRequested: {
                root.pinned = true
                Qt.callLater(root.switchWindowMode)
            }
            onKeyboardClosed: {
                PluginService.setGlobalVar(root.pluginId, "open", false)
                ydotoolService.releaseAllKeys()
                Qt.callLater(root.releaseIdleWindows)
            }
        }
    }

    LazyLoader {
        id: floatingLoader
        active: false

        FloatingKeyboardWindow {
            ydotool: ydotoolService
            fixedItems: root.fixedItems
            userScale: root.userScale
            onFixedItemsEdited: items => root.setFixedItems(items)
            onUnpinRequested: {
                root.pinned = false
                Qt.callLater(root.switchWindowMode)
            }
            onKeyboardClosed: {
                PluginService.setGlobalVar(root.pluginId, "open", false)
                ydotoolService.releaseAllKeys()
                Qt.callLater(root.releaseIdleWindows)
            }
        }
    }

    // Pin/unpin swaps which window class is showing the keyboard (docked
    // PanelWindow vs floating FloatingWindow -- two different Quickshell
    // window types, not a property toggle on one window). Unloading the
    // loader that owns the window currently running *its own* pinRequested/
    // unpinRequested handler needs to happen after that handler returns, not
    // from inside it -- hence the Qt.callLater at each call site landing
    // here rather than touching the loaders directly.
    function switchWindowMode() {
        // The window carrying the latched-modifier buttons is about to be
        // destroyed, so anything it is holding down has to come up first.
        ydotoolService.releaseAllKeys()
        dockedLoader.active = false
        floatingLoader.active = false
        openKeyboard()
    }

    // Closing frees the window, but only once it is certain nothing reopened
    // it in the meantime -- this runs a tick after keyboardClosed, and a
    // toggle-spam or close-then-open in that gap would otherwise destroy the
    // window that was just created.
    function releaseIdleWindows() {
        if (root.keyboardOpen)
            return
        dockedLoader.active = false
        floatingLoader.active = false
    }

    function openKeyboard() {
        if (root.pinned) {
            floatingLoader.active = true
            floatingLoader.item.show()
        } else {
            dockedLoader.active = true
            dockedLoader.item.show()
        }
        PluginService.setGlobalVar(root.pluginId, "open", true)
    }

    function closeKeyboard() {
        if (dockedLoader.item)
            dockedLoader.item.hide()
        if (floatingLoader.item)
            floatingLoader.item.hide()
    }

    Connections {
        target: PluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId !== root.pluginId || varName !== "open")
                return
            const wantOpen = PluginService.getGlobalVar(root.pluginId, "open", false)
            if (wantOpen && !root.keyboardOpen)
                root.openKeyboard()
            else if (!wantOpen && root.keyboardOpen)
                root.closeKeyboard()
        }
    }

    IpcHandler {
        target: "virtualKeyboard"

        function toggle(): string {
            if (root.keyboardOpen) {
                root.closeKeyboard()
                return "VIRTUALKEYBOARD_CLOSED"
            }
            root.openKeyboard()
            return "VIRTUALKEYBOARD_OPENED"
        }

        function open(): string {
            root.openKeyboard()
            return "VIRTUALKEYBOARD_OPENED"
        }

        function close(): string {
            root.closeKeyboard()
            return "VIRTUALKEYBOARD_CLOSED"
        }

        function toggleAvoid(): string {
            root.avoidWindows = !root.avoidWindows
            return root.avoidWindows ? "VIRTUALKEYBOARD_AVOID_ON" : "VIRTUALKEYBOARD_AVOID_OFF"
        }

        function toggleFloat(): string {
            root.pinned = !root.pinned
            if (root.keyboardOpen)
                Qt.callLater(root.switchWindowMode)
            return root.pinned ? "VIRTUALKEYBOARD_FLOATING" : "VIRTUALKEYBOARD_DOCKED"
        }

        function togglePanel(): string {
            ydotoolService.panelOpen = !ydotoolService.panelOpen
            if (!ydotoolService.panelOpen)
                ydotoolService.editing = false
            return ydotoolService.panelOpen ? "VIRTUALKEYBOARD_PANEL" : "VIRTUALKEYBOARD_KEYS"
        }

        function toggleEdit(): string {
            ydotoolService.editing = !ydotoolService.editing
            return ydotoolService.editing ? "VIRTUALKEYBOARD_EDIT_ON" : "VIRTUALKEYBOARD_EDIT_OFF"
        }

        function setFixed(csv: string): string {
            const items = csv.length ? csv.split(",") : []
            root.setFixedItems(items)
            return "OK:" + items.join(",")
        }

        function getFixed(): string {
            return root.fixedItems.join(",")
        }

        function getScale(): string {
            return String(ydotoolService.userScale)
        }
    }
}
