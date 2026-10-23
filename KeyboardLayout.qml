import QtQuick
import QtQuick.Layouts
import "layout-us.js" as LayoutUs

ColumnLayout {
    id: root

    property var ydotool: null
    property real keyScale: 1

    spacing: 6 * keyScale

    Repeater {
        model: LayoutUs.rows

        delegate: RowLayout {
            id: keyRow
            required property var modelData
            spacing: 6 * root.keyScale

            Repeater {
                model: keyRow.modelData

                delegate: Key {
                    id: keyDelegate
                    required property var modelData
                    keyData: modelData
                    ydotool: root.ydotool
                    keyScale: root.keyScale
                    Layout.fillWidth: modelData.shape === "space" || modelData.shape === "expand"
                }
            }
        }
    }
}
