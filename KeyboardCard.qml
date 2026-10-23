import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Common
import qs.Widgets
import "Functions.js" as Fn

StyledRect {
    id: root

    required property var ydotool
    // True while shown in the floating (movable overlay) window.
    property bool floating: false
    property bool avoidEnabled: true
    property real keyScale: 1

    readonly property bool editing: !!ydotool && ydotool.editing
    readonly property bool listOpen: !!ydotool && ydotool.panelOpen
    readonly property bool resizing: !!ydotool && ydotool.resizing

    // Functions pinned to the fixed row, in order (owned by the daemon so they
    // survive the window being destroyed, and persisted there).
    property var fixedItems: ["drag", "float", "pin"]

    readonly property var allFunctions: Fn.ids()
    readonly property var listItems: allFunctions.filter(f => fixedItems.indexOf(f) < 0)
    // Function ids that are currently active (highlighted border).
    readonly property var activeIds: allFunctions.filter(f => Fn.isActive(f, floating, avoidEnabled, resizing, ydotool ? ydotool.keyboardOpacity : 1))
    // Y offset (inside the card) of the BOTTOM of the fixed shortcut row:
    // card top padding (8) + the row height. The floating window uses it so the
    // function area can never be dragged off the screen.
    readonly property real fixedRowBottom: 8 + shortcutRow.height

    signal pinClicked
    signal hideClicked
    signal floatClicked
    // Fixed-row contents changed (edit mode); the daemon persists them.
    signal fixedItemsEdited(var items)
    // Emitted while the "拖动" shortcut is dragged, in scene coordinates.
    signal dragStarted
    signal dragMoved(real dx, real dy)

    // ---- item reorder drag (edit mode) ----
    property string dragFrom: ""
    property int dragIndex: -1
    property string dragId: ""
    property real dragX: 0
    property real dragY: 0

    function beginItemDrag(from, index, id, x, y) {
        dragFrom = from
        dragIndex = index
        dragId = id
        dragX = x
        dragY = y
    }

    function moveItemDrag(x, y) {
        dragX = x
        dragY = y
    }

    function endItemDrag(x, y) {
        if (dragFrom === "")
            return
        const from = dragFrom
        const index = dragIndex
        const id = dragId
        dragFrom = ""
        dragIndex = -1
        dragId = ""

        const ins = shortcutRow.insertIndexAt(x, y)
        if (from === "fixed") {
            if (ins < 0) {
                // Dragged out of the fixed row -> unpin.
                root.fixedItemsEdited(fixedItems.filter((f, i) => i !== index))
            } else {
                const arr = fixedItems.slice()
                const moved = arr.splice(index, 1)[0]
                arr.splice(ins > index ? ins - 1 : ins, 0, moved)
                root.fixedItemsEdited(arr)
            }
        } else if (ins >= 0) {
            const arr = fixedItems.slice()
            arr.splice(ins, 0, id)
            root.fixedItemsEdited(arr)
        }
    }

    function dispatch(id) {
        if (id === "float") {
            root.floatClicked()
            return
        }
        if (id === "pin") {
            root.pinClicked()
            return
        }
        if (id === "resize") {
            root.ydotool.resizing = !root.ydotool.resizing
            return
        }
        if (id === "opacity") {
            // Cycle through a few levels (settings has a continuous slider too).
            const levels = [1.0, 0.8, 0.6, 0.4]
            const cur = root.ydotool.keyboardOpacity
            let idx = 0
            for (let i = 0; i < levels.length; i++) {
                if (Math.abs(levels[i] - cur) < 0.05) {
                    idx = i
                    break
                }
            }
            root.ydotool.keyboardOpacity = levels[(idx + 1) % levels.length]
            return
        }
        const argv = Fn.cmdFor(id)
        if (argv) {
            const p = cmdProc.createObject(root, { argv: argv })
            p.running = true
        }
    }

    // One-shot process for functions that run a command (niri, dms ipc, ...).
    Component {
        id: cmdProc
        Process {
            property var argv: []
            command: argv
            onExited: destroy()
        }
    }

    readonly property string dragIcon: dragId !== "" ? Fn.info(dragId, floating, avoidEnabled).icon : ""

    radius: Theme.cornerRadius
    color: Theme.readableSurface
    // Keyboard opacity (adjustable from the settings slider or the 透明度 key).
    opacity: root.ydotool ? root.ydotool.keyboardOpacity : 1
    border.width: (root.editing || root.resizing) ? 2 : 1
    border.color: (root.editing || root.resizing) ? Theme.primary : Theme.outlineVariant
    width: content.implicitWidth + 16
    height: content.implicitHeight + 16

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: 6

        ShortcutRow {
            id: shortcutRow
            Layout.fillWidth: true
            ydotool: root.ydotool
            keyScale: root.keyScale
            floating: root.floating
            avoidEnabled: root.avoidEnabled
            editing: root.editing
            items: root.fixedItems
            activeIds: root.activeIds
            onToggleList: root.ydotool.panelOpen = !root.ydotool.panelOpen
            onConfirmEdit: root.ydotool.editing = false
            onHideRequested: root.hideClicked()
            onFunctionTriggered: id => root.dispatch(id)
            onDragStarted: root.dragStarted()
            onDragMoved: (dx, dy) => root.dragMoved(dx, dy)
            onItemDragBegin: (from, index, id, x, y) => root.beginItemDrag(from, index, id, x, y)
            onItemDragMove: (x, y) => root.moveItemDrag(x, y)
            onItemDragEnd: (x, y) => root.endItemDrag(x, y)
        }

        // Key grid / all-functions page. Both are siblings sized to the key
        // grid's own height, so switching between them never resizes the card.
        Item {
            id: viewArea
            Layout.fillWidth: true
            Layout.preferredHeight: keys.implicitHeight
            implicitWidth: keys.implicitWidth
            implicitHeight: keys.implicitHeight

            KeyboardLayout {
                id: keys
                anchors.fill: parent
                visible: !root.listOpen
                ydotool: root.ydotool
                keyScale: root.keyScale
            }

            FunctionListPage {
                anchors.fill: parent
                visible: root.listOpen
                ydotool: root.ydotool
                keyScale: root.keyScale
                floating: root.floating
                avoidEnabled: root.avoidEnabled
                editing: root.editing
                items: root.listItems
                activeIds: root.activeIds
                onToggleEdit: root.ydotool.editing = !root.ydotool.editing
                onFunctionTriggered: id => root.dispatch(id)
                onItemDragBegin: (from, index, id, x, y) => root.beginItemDrag(from, index, id, x, y)
                onItemDragMove: (x, y) => root.moveItemDrag(x, y)
                onItemDragEnd: (x, y) => root.endItemDrag(x, y)
            }
        }
    }

    // Resize grip (bottom-right): two diagonal lines; drag to scale the whole
    // keyboard uniformly about its top-left corner.
    Item {
        id: resizeGrip
        visible: root.resizing
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        width: 22
        height: 22
        z: 90

        Canvas {
            id: gripCanvas
            anchors.fill: parent
            onVisibleChanged: if (visible) requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = Theme.primary
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                const w = width
                const h = height
                ctx.beginPath()
                ctx.moveTo(w * 0.30, h - 3)
                ctx.lineTo(w - 3, h * 0.30)
                ctx.moveTo(w * 0.70, h - 3)
                ctx.lineTo(w - 3, h * 0.70)
                ctx.stroke()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            property real anchorX: 0
            property real anchorY: 0
            property real baseW: 1
            property real baseH: 1
            onPressed: mouse => {
                const tl = root.mapToItem(null, 0, 0)
                anchorX = tl.x
                anchorY = tl.y
                const s = root.keyScale > 0.01 ? root.keyScale : 1
                baseW = Math.max(1, root.width / s)
                baseH = Math.max(1, root.height / s)
            }
            onPositionChanged: mouse => {
                if (!pressed || !root.ydotool)
                    return
                const p = mapToItem(null, mouse.x, mouse.y)
                // The bottom-right corner follows the finger, top-left fixed;
                // uniform scale = whichever axis the finger pushed further.
                const rx = (p.x - anchorX) / baseW
                const ry = (p.y - anchorY) / baseH
                root.ydotool.userScale = Math.max(0.4, Math.min(2.5, Math.max(rx, ry)))
            }
        }
    }

    // Ghost icon following the pointer while reordering.
    DankIcon {
        id: ghost
        visible: root.dragId !== ""
        name: root.dragIcon
        size: Theme.iconSize * 1.4
        color: Theme.primary
        z: 100

        property point pt: root.dragId !== "" ? root.mapFromItem(null, root.dragX, root.dragY) : Qt.point(0, 0)

        x: pt.x - width / 2
        y: pt.y - height / 2
    }
}
