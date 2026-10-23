import QtQuick
import qs.Common
import qs.DCommon.Common as DCommon
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "virtualKeyboard"

    function tr(term) {
        return I18n.trFor("virtualKeyboard", term);
    }

    StyledText {
        width: parent.width
        text: tr("Toggle the keyboard with `dms ipc call virtualKeyboard toggle` (bindable to a compositor keybind), or add the optional bar pill to DankBar.")
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "pinnedOnStartup"
        label: tr("Float by default")
        description: tr("Open the keyboard as a movable floating window rather than docked at the bottom of the screen")
        defaultValue: false
    }
}
