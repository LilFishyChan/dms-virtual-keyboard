import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

// Floating (movable) keyboard.
//
// Deliberately a layer-shell PanelWindow, NOT a FloatingWindow: an xdg-toplevel
// (Quickshell's FloatingWindow) always takes keyboard focus, which would make
// ydotool's injected keys land on the keyboard itself instead of the app.
// A layer surface with WlrKeyboardFocus.None receives pointer/touch input but
// never claims the keyboard, so typing still goes to the focused app.
//
// The surface is full-screen and NEVER moves; the card is moved *inside* it.
// That is deliberate: if the surface itself moves while dragging, the pointer's
// surface-local coordinates shift with it and feed back into the position, so
// the card accelerates away ("a light swipe and it flies"). With a stationary
// surface the card can be positioned with plain pointer coordinates.
PanelWindow {
    id: root

    required property var ydotool
    property bool keyboardVisible: false
    // Uniform user scale from the resize function (owned/persisted by the daemon).
    property real userScale: 1

    signal keyboardClosed
    // Handing back to the daemon: close this window and reopen the docked one.
    signal unpinRequested
    // Fixed shortcut row contents (owned/persisted by the daemon).
    property var fixedItems: ["drag", "float", "pin"]
    signal fixedItemsEdited(var items)

    // Card top-left, in screen coordinates (the surface covers the screen).
    property real posX: 0
    property real posY: 0
    // Card position when the current drag started.
    property real dragStartX: 0
    property real dragStartY: 0

    // Floating keyboards are smaller than the docked one so there is room to
    // move them around (leave ~80px per side in portrait).
    readonly property real floatScale: Math.max(0.6, Math.min(1, ((root.screen ? root.screen.width : 800) - 176) / 843))

    // The compositor places a full-area layer surface inside the USABLE AREA
    // (i.e. below the bar's exclusive zone), so this surface's origin is offset
    // from the screen origin. Card x/y are surface-relative while posX/posY are
    // SCREEN coordinates -- mixing the two let the keyboard be pushed past the
    // bottom edge.
    readonly property real offsetX: Math.max(0, (root.screen ? root.screen.width : root.width) - root.width)
    readonly property real offsetY: Math.max(0, (root.screen ? root.screen.height : root.height) - root.height)

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function minX() {
        return Math.min(root.offsetX, root.maxX())
    }

    function minY() {
        return Math.min(root.offsetY, root.maxY())
    }

    function maxX() {
        return Math.max(0, (root.screen ? root.screen.width : card.width) - card.width)
    }

    // The top (fixed shortcut) row must always stay fully on screen -- it is the
    // keyboard's handle. The key area below it may be pushed off.
    function maxY() {
        const sh = root.screen ? root.screen.height : card.height
        return Math.max(0, sh - card.fixedRowBottom)
    }

    // Always center on the screen (the floating position is not remembered).
    function applyPosition() {
        const sw = root.screen ? root.screen.width : card.width
        const sh = root.screen ? root.screen.height : card.height
        root.posX = root.clamp(Math.round((sw - card.width) / 2), root.minX(), root.maxX())
        root.posY = root.clamp(Math.round((sh - card.height) / 2), root.minY(), root.maxY())
    }

    function show() {
        keyboardVisible = true
        Qt.callLater(root.applyPosition)
    }

    function hide() {
        if (!keyboardVisible)
            return
        keyboardVisible = false
        keyboardClosed()
    }

    visible: keyboardVisible
    color: "transparent"

    // Full-screen and stationary (see the note above).
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: 0
    margins.left: 0
    margins.right: 0
    margins.bottom: 0
    exclusiveZone: 0

    onWidthChanged: root.applyPosition()
    onHeightChanged: root.applyPosition()

    WlrLayershell.namespace: "dms:plugins:virtualKeyboard:floating"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the card is interactive; the rest of the surface stays click-through.
    mask: Region {
        item: card
    }

    KeyboardCard {
        id: card

        x: root.posX - root.offsetX
        y: root.posY - root.offsetY
        ydotool: root.ydotool
        floating: true
        keyScale: root.floatScale * root.userScale
        fixedItems: root.fixedItems

        onFixedItemsEdited: items => root.fixedItemsEdited(items)
        onFloatClicked: root.unpinRequested()
        onHideClicked: root.hide()

        onDragStarted: {
            root.dragStartX = root.posX
            root.dragStartY = root.posY
        }
        onDragMoved: (dx, dy) => {
            root.posX = root.clamp(root.dragStartX + dx, root.minX(), root.maxX())
            root.posY = root.clamp(root.dragStartY + dy, root.minY(), root.maxY())
        }
    }

    // Keep it centered as the card size settles (first layout, resize).
    Connections {
        target: card
        function onWidthChanged() {
            root.applyPosition()
        }
        function onHeightChanged() {
            root.applyPosition()
        }
    }
}
