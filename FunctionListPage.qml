import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "Functions.js" as Fn

// "全部快捷功能列表" page -- shown in place of the key grid when the 4-square
// button is toggled. Lists every shortcut function that is NOT already pinned
// to the fixed row, each 3 standard key-widths wide. A pencil button fixed
// bottom-right enters edit mode, in which items can be dragged into the fixed
// row (and back) to reorder / assign.
Item {
    id: root

    property var ydotool
    property real keyScale: 1
    property bool floating: false
    property bool avoidEnabled: true
    property bool editing: false
    property var items: []
    property var activeIds: []

    signal toggleEdit
    signal functionTriggered(string id)
    signal itemDragBegin(string from, int index, string id, real sceneX, real sceneY)
    signal itemDragMove(real sceneX, real sceneY)
    signal itemDragEnd(real sceneX, real sceneY)

    readonly property real unit: 45 * keyScale
    readonly property real itemW: unit * 3
    readonly property real itemH: unit * 0.75
    readonly property real gap: 6 * keyScale

    implicitWidth: flow.width
    implicitHeight: unit * 5

    function contains(sceneX, sceneY) {
        const tl = mapToItem(null, 0, 0)
        return sceneX >= tl.x && sceneX <= tl.x + width && sceneY >= tl.y && sceneY <= tl.y + height
    }

    Flow {
        id: flow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: root.gap

        Repeater {
            model: root.items

            delegate: StyledRect {
                id: item
                required property var modelData
                required property int index

                readonly property var fi: Fn.info(modelData, root.floating, root.avoidEnabled)
                readonly property bool dis: Fn.isDisabled(modelData, root.floating)
                readonly property bool act: root.activeIds.indexOf(modelData) !== -1

                width: root.itemW
                height: root.itemH
                radius: Theme.cornerRadius
                color: dis ? Theme.withAlpha(Theme.surfaceText, 0.04) : Theme.withAlpha(Theme.primary, 0.08)
                border.width: (root.editing || act) ? 1 : 0
                border.color: Theme.primary
                opacity: dis ? 0.45 : 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    DankIcon {
                        name: item.fi.icon
                        size: Theme.iconSize * root.keyScale
                        color: item.dis ? Theme.surfaceVariantText : Theme.surfaceText
                    }
                    StyledText {
                        text: item.fi.label
                        font.pixelSize: Theme.fontSizeSmall * root.keyScale
                        color: item.dis ? Theme.surfaceVariantText : Theme.surfaceText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.editing || !item.dis
                    property real sx: 0
                    property real sy: 0

                    onPressed: mouse => {
                        const p = mapToItem(null, mouse.x, mouse.y)
                        sx = p.x
                        sy = p.y
                        if (root.editing)
                            root.itemDragBegin("list", item.index, item.modelData, p.x, p.y)
                    }

                    onPositionChanged: mouse => {
                        if (!pressed || !root.editing)
                            return
                        const p = mapToItem(null, mouse.x, mouse.y)
                        root.itemDragMove(p.x, p.y)
                    }

                    onReleased: mouse => {
                        const p = mapToItem(null, mouse.x, mouse.y)
                        if (root.editing)
                            root.itemDragEnd(p.x, p.y)
                        else
                            root.functionTriggered(item.modelData)
                    }
                }
            }
        }
    }

    StyledText {
        anchors.top: flow.bottom
        anchors.topMargin: 12 * keyScale
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.items.length === 0
        text: "全部功能都已固定"
        font.pixelSize: Theme.fontSizeSmall * root.keyScale
        color: Theme.surfaceVariantText
    }

    // Pencil: toggle edit mode.
    StyledRect {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: itemH
        height: itemH
        radius: Theme.cornerRadius
        color: root.editing ? Theme.primarySelected : Theme.withAlpha(Theme.primary, 0.08)

        DankIcon {
            anchors.centerIn: parent
            name: "edit"
            size: Theme.iconSize * root.keyScale
            color: Theme.surfaceText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggleEdit()
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6 * keyScale
        visible: root.editing
        text: "按住并拖动以自定义"
        font.pixelSize: Theme.fontSizeSmall * root.keyScale
        color: Theme.surfaceVariantText
    }
}
