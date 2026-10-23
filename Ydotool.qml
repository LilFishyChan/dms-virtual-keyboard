import QtQuick
import Quickshell.Io

Item {
    id: root

    // 0 = plain, 1 = shift latched (tapped once; released by the next normal
    // key or by tapping shift again). No caps-lock.
    property int shiftMode: 0
    readonly property var shiftKeycodes: [42, 54]
    // Keycodes currently held down by a latched mod key. Tracked here rather
    // than on the keys themselves because the window owning them is destroyed
    // on close and on a pin/unpin swap, and a keycode still held at the kernel
    // level after its key is gone can never be released by pressing it again.
    property var heldKeycodes: []
    // Fn layer latched state (toggled by a fnkey).
    property bool fnActive: false
    // Shortcut (extra functions) panel open state, toggled by the apps key.
    property bool panelOpen: false
    // Shortcut-area edit (customise) mode.
    property bool editing: false
    // Resize mode: highlighted border + a bottom-right grip while true.
    property bool resizing: false
    // Uniform user scale applied on top of the window's base scale.
    property real userScale: 1
    // Keyboard opacity (0.3 - 1.0). Mirrored to the plugin setting.
    // (Named keyboardOpacity: Item.opacity is FINAL and cannot be redeclared.)
    property real keyboardOpacity: 1

    // The press itself already went out on the key's own press event -- this
    // only records that it was never released.
    function retainHeld(keycode) {
        if (heldKeycodes.indexOf(keycode) === -1)
            heldKeycodes = heldKeycodes.concat([keycode])
    }

    function releaseHeld(keycode) {
        release(keycode)
        heldKeycodes = heldKeycodes.filter(k => k !== keycode)
    }

    function press(keycode) {
        spawn(keycode + ":1")
    }

    function release(keycode) {
        spawn(keycode + ":0")
    }

    function releaseShiftKeys() {
        root.shiftMode = 0
        for (var i = 0; i < shiftKeycodes.length; i++)
            release(shiftKeycodes[i])
    }

    function releaseAllKeys() {
        releaseShiftKeys()
        for (var i = 0; i < heldKeycodes.length; i++)
            release(heldKeycodes[i])
        heldKeycodes = []
        fnActive = false
        resizing = false
    }

    function spawn(arg) {
        var proc = ydotoolProcess.createObject(root, {keyArg: arg})
        proc.running = true
    }

    Component {
        id: ydotoolProcess

        Process {
            property string keyArg: ""
            command: ["ydotool", "key", keyArg]
            onExited: exitCode => {
                if (exitCode !== 0)
                    console.warn("virtualKeyboard: ydotool exited", exitCode, "-", keyArg)
                destroy()
            }
        }
    }
}
