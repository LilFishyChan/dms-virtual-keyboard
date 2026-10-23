import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    property bool keyboardOpen: PluginService.getGlobalVar(root.pluginId, "open", false)

    Connections {
        target: PluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === root.pluginId && varName === "open")
                root.keyboardOpen = PluginService.getGlobalVar(root.pluginId, "open", false)
        }
    }

    pillClickAction: () => {
        PluginService.setGlobalVar(root.pluginId, "open", !root.keyboardOpen)
    }

    // Bare glyph, like the built-in bar widgets: the host draws the pill
    // background and its equal padding. Drawing our own chip on top of it
    // only pushes the icon into the pill edges.
    horizontalBarPill: Component {
        DankIcon {
            name: "keyboard"
            size: root.iconSize
            color: root.keyboardOpen ? Theme.primary : Theme.surfaceText
        }
    }

    verticalBarPill: horizontalBarPill
}
