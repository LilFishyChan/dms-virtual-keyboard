import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "Functions.js" as Fn

// The "固定快捷功能" row, always shown directly above the number row.
//
// [4-square][ ...fixed items... ][hide] -- the fixed area sits between the two
// fixed-width buttons. The fixed items are laid out dynamically: however many
// are assigned, they divide the middle width evenly (no empty placeholders).
//
// Styles: normal = icon + background, no border. Active = primary border.
// Disabled (e.g. drag while docked, avoid while floating) = greyed out.
StyledRect {
    id: root

    property var ydotool
    property real keyScale: 1
    property bool floating: false
    property bool avoidEnabled: true
    property bool editing: false
    // Function ids currently pinned to the row.
    property var items: ["drag", "float", "pin"]
    // Function ids that are currently active (highlighted border).
    property var activeIds: []

    signal toggleList
    signal confirmEdit
    signal hideRequested
    signal functionTriggered(string id)
    signal dragStarted
    signal dragMoved(real dx, real dy)
    // Item reorder drag (edit mode), scene coordinates.
    signal itemDragBegin(string from, int index, string id, real sceneX, real sceneY)
    signal itemDragMove(real sceneX, real sceneY)
    signal itemDragEnd(real sceneX, real sceneY)

    readonly property real unit: 45 * keyScale
    // The function row is a bit shorter than a normal key row.
    readonly property real rowHeight: unit * 0.75

    radius: Theme.cornerRadius
    color: "transparent"
    border.width: root.editing ? 2 : 0
    border.color: Theme.primary
    implicitHeight: rowHeight

    // Insertion index for a drop at (sceneX, sceneY), or -1 if not over the row.
    function insertIndexAt(sceneX, sceneY) {
        const tl = middle.mapToItem(null, 0, 0)
        if (sceneY < tl.y - rowHeight * 0.6 || sceneY > tl.y + middle.height + rowHeight * 0.6)
            return -1
        let idx = 0
        for (let i = 0; i < itemRepeater.count; i++) {
            const it = itemRepeater.itemAt(i)
            if (!it)
                continue
            const c = it.mapToItem(null, it.width / 2, 0).x
            if (sceneX > c)
                idx = i + 1
        }
        return idx
    }

    RowLayout {
        anchors.fill: parent
        spacing: 6 * keyScale

        // 4-square button / checkmark.
        StyledRect {
            Layout.preferredWidth: root.rowHeight
            Layout.preferredHeight: root.rowHeight
            radius: Theme.cornerRadius
            color: root.editing ? Theme.primarySelected : Theme.withAlpha(Theme.primary, 0.08)

            DankIcon {
                anchors.centerIn: parent
                name: root.editing ? "check" : "grid_view"
                size: Theme.iconSize * root.keyScale
                color: Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.editing ? root.confirmEdit() : root.toggleList()
            }
        }

        // Fixed items, dividing the middle width evenly.
        RowLayout {
            id: middle
            Layout.fillWidth: true
            spacing: 6 * keyScale

            Repeater {
                id: itemRepeater
                model: root.items

                delegate: StyledRect {
                    id: slot
                    required property var modelData
                    required property int index

                    readonly property var fi: Fn.info(modelData, root.floating, root.avoidEnabled)
                    readonly property bool dis: Fn.isDisabled(modelData, root.floating)
                    readonly property bool act: root.activeIds.indexOf(modelData) !== -1

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.rowHeight
                    radius: Theme.cornerRadius
                    color: dis ? Theme.withAlpha(Theme.surfaceText, 0.04) : Theme.withAlpha(Theme.primary, 0.08)
                    border.width: (root.editing || act) ? 1 : 0
                    border.color: Theme.primary
                    opacity: dis ? 0.45 : 1

                    DankIcon {
                        anchors.centerIn: parent
                        name: slot.fi.icon
                        size: Theme.iconSize * root.keyScale
                        color: slot.dis ? Theme.surfaceVariantText : Theme.surfaceText
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.editing || !slot.dis
                        property real sx: 0
                        property real sy: 0

                        onPressed: mouse => {
                            const p = mapToItem(null, mouse.x, mouse.y)
                            sx = p.x
                            sy = p.y
                            if (root.editing)
                                root.itemDragBegin("fixed", slot.index, slot.modelData, p.x, p.y)
                            else if (slot.modelData === "drag")
                                root.dragStarted()
                        }

                        onPositionChanged: mouse => {
                            if (!pressed)
                                return
                            const p = mapToItem(null, mouse.x, mouse.y)
                            if (root.editing)
                                root.itemDragMove(p.x, p.y)
                            else if (slot.modelData === "drag")
                                root.dragMoved(p.x - sx, p.y - sy)
                        }

                        onReleased: mouse => {
                            const p = mapToItem(null, mouse.x, mouse.y)
                            if (root.editing)
                                root.itemDragEnd(p.x, p.y)
                            else if (slot.modelData && slot.modelData !== "drag")
                                root.functionTriggered(slot.modelData)
                        }
                    }
                }
            }
        }

        // Hide keyboard, pinned to the top-right.
        StyledRect {
            Layout.preferredWidth: root.rowHeight
            Layout.preferredHeight: root.rowHeight
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.primary, 0.08)

            DankIcon {
                anchors.centerIn: parent
                name: "keyboard_hide"
                size: Theme.iconSize * root.keyScale
                color: Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.editing
                onClicked: root.hideRequested()
            }
        }
    }
}
