import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: root

    required property var ydotool
    property bool keyboardVisible: false
    // Toggled by the pin button: reserve space at the bottom so windows reflow
    // above the keyboard, instead of the keyboard overlaying them.
    property bool avoidWindows: true

    // Scale the key grid so the card fills the available width edge to edge,
    // capped at its natural size. The card is (widest key row ~843px) * keyScale
    // + 16px padding, so solve keyScale for a target card width of availWidth.
    // Landscape (1280) is capped at 1; portrait (800) fills the whole width
    // (~0.93). Use `screen` because root.width tracks implicitWidth.
    readonly property real availWidth: screen ? screen.width : root.width
    // User scale from the resize function multiplies the fit-to-width scale.
    property real userScale: 1
    readonly property real keyScale: Math.max(0.6, Math.min(1, (availWidth - 16) / 843)) * userScale

    signal keyboardClosed
    // Pin clicked while docked: this window has no way to become a
    // FloatingWindow itself (different Quickshell window class entirely),
    // so it asks the daemon to close this one and open the floating variant.
    signal pinRequested
    // Same hand-off, but for switching into the movable floating keyboard.
    signal floatRequested
    // Fixed shortcut row contents (owned/persisted by the daemon).
    property var fixedItems: ["drag", "float", "pin"]
    signal fixedItemsEdited(var items)

    function show() {
        keyboardVisible = true
    }

    function hide() {
        if (!keyboardVisible)
            return
        keyboardVisible = false
        keyboardClosed()
    }

    visible: keyboardVisible
    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }

    // Reserve the keyboard's height along the bottom edge so tiled/maximized
    // windows reflow above it instead of being covered. 0 while hidden (the
    // surface is unmapped then anyway).
    exclusiveZone: (root.keyboardVisible && root.avoidWindows) ? Math.ceil(card.height + 8) : 0
    implicitWidth: card.width
    implicitHeight: card.height + 8

    WlrLayershell.namespace: "dms:plugins:virtualKeyboard"
    WlrLayershell.layer: WlrLayer.Overlay
    // The keyboard injects keys via ydotool (raw uinput events), which the
    // compositor routes to whatever surface currently holds keyboard focus.
    // If this layer surface took focus (OnDemand) the injected keys would land
    // on the keyboard itself instead of the app. Never claim keyboard focus;
    // pointer/touch input still reaches the keys.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: card
    }

    WindowBlur {
        targetWindow: root
        blurX: card.x
        blurY: card.y
        blurWidth: root.keyboardVisible ? card.width : 0
        blurHeight: root.keyboardVisible ? card.height : 0
        blurRadius: Theme.cornerRadius
    }

    FocusScope {
        anchors.fill: parent
        focus: root.keyboardVisible

        Keys.onEscapePressed: root.hide()

        KeyboardCard {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            ydotool: root.ydotool
            avoidEnabled: root.avoidWindows
            keyScale: root.keyScale
            fixedItems: root.fixedItems
            onFixedItemsEdited: items => root.fixedItemsEdited(items)
            onPinClicked: root.pinRequested()
            onFloatClicked: root.floatRequested()
            onHideClicked: root.hide()
        }
    }
}
