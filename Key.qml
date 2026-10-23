import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "KeyShape.js" as KeyShape

StyledRect {
    id: root

    required property var keyData
    property var ydotool: null

    readonly property string keytype: keyData.keytype
    readonly property string shape: keyData.shape
    readonly property int keycode: keyData.keycode || 0
    readonly property bool isFnKey: keytype === "fnkey"
    readonly property bool isAppsKey: keytype === "apps"
    readonly property bool fnActive: !!ydotool && ydotool.fnActive
    readonly property bool shiftActive: !!ydotool && ydotool.shiftMode > 0
    // Per-key overrides: shiftKeycode while Shift is held, else fnKeycode while
    // Fn is latched, else the base keycode.
    readonly property int effectiveKeycode: {
        if (shiftActive && keyData.shiftKeycode)
            return keyData.shiftKeycode
        if (fnActive && keyData.fnKeycode)
            return keyData.fnKeycode
        return keycode
    }
    readonly property bool isEmpty: shape === "empty" || keytype === "spacer"
    readonly property bool isShiftKey: !!ydotool && ydotool.shiftKeycodes.indexOf(keycode) !== -1
    readonly property bool isBackspace: keyData.label === "Backspace"
    readonly property bool isEnter: keyData.label === "Enter"
    readonly property bool latched: (isShiftKey && ydotool.shiftMode > 0) || (keytype === "modkey" && !isShiftKey && modToggled) || (isFnKey && fnActive)

    // Sticky modkeys (Ctrl/Alt) latch on the first tap and release on the
    // second, same as upstream's OskKey "modkey" branch.
    property bool modToggled: false
    property bool isPressed: false
    // Set on Shift press: whether Shift was already latched (i.e. this is the
    // second tap, which turns it back off). No double-tap caps-lock.
    property bool shiftWasLatched: false

    // Scaled from the window so the keyboard can shrink to fit narrow
    // (portrait) screens without clipping its right-hand columns.
    property real keyScale: 1
    readonly property real baseWidth: 45 * keyScale
    readonly property real baseHeight: 45 * keyScale

    width: baseWidth * KeyShape.widthMultiplier(shape)
    height: baseHeight * KeyShape.heightMultiplier(shape)
    // Also tell the layout explicitly (an explicit width/height binding can be
    // overwritten by RowLayout; the preferred size is what it actually uses).
    Layout.preferredWidth: baseWidth * KeyShape.widthMultiplier(shape)
    Layout.preferredHeight: baseHeight * KeyShape.heightMultiplier(shape)
    visible: !isEmpty
    enabled: !isEmpty
    radius: Theme.cornerRadius
    // A light accent tint rather than a neutral grey tile -- keys pick up
    // DMS's own primary color at low alpha (same family as Theme.primaryHover),
    // so the keyboard reads as part of the theme instead of a flat grid of
    // grey blocks pasted over the blurred card.
    // Keys darken noticeably while held (touch needs the feedback).
    color: isPressed
           ? Theme.withAlpha(Qt.darker(Theme.primary, 1.4), 0.32)
           : latched ? Theme.primarySelected : Theme.withAlpha(Theme.primary, 0.08)

    DankIcon {
        anchors.centerIn: parent
        visible: root.isAppsKey || root.isEnter || (root.isBackspace && !root.shiftActive)
        name: root.isAppsKey ? "grid_view" : (root.isEnter ? "keyboard_return" : "backspace")
        size: Theme.iconSize * root.keyScale
        color: root.latched ? Theme.primary : Theme.surfaceText
    }

    // Letters skip the corner label -- shift+letter is just the uppercase
    // form, obvious without a hint. Only symbol/number keys (whose shifted
    // character isn't guessable) get one.
    readonly property bool isLetter: /^[a-zA-Z]$/.test(keyData.label)
    readonly property bool showsSecondaryLabel: !isBackspace && !isEnter && !isShiftKey && !isLetter && !!keyData.labelShift

    StyledText {
        anchors.centerIn: parent
        visible: !root.isEnter && !root.isAppsKey && (!root.isBackspace || root.shiftActive)
        text: (root.isBackspace && root.shiftActive) ? "Del"
              : (root.shiftActive && root.keyData.shiftLabel) ? root.keyData.shiftLabel
              : (root.fnActive && root.keyData.fnLabel) ? root.keyData.fnLabel
              : KeyShape.labelFor(root.keyData, root.ydotool ? root.ydotool.shiftMode : 0)
        font.pixelSize: (root.shape === "fn" ? Theme.fontSizeSmall : Theme.fontSizeMedium) * root.keyScale
        color: root.latched ? Theme.primary : Theme.surfaceText
    }

    // A physical keycap shows both characters at once (main centered, the
    // shifted one small in the corner) rather than only revealing it once
    // shift is actually held -- otherwise there's no way to tell `1` gives
    // `!` without pressing shift first.
    StyledText {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 3 * root.keyScale
        visible: root.showsSecondaryLabel
        text: !root.ydotool ? "" : (root.ydotool.shiftMode === 0 ? (root.keyData.labelShift || "") : root.keyData.label)
        font.pixelSize: (Theme.fontSizeSmall - 2) * root.keyScale
        color: root.latched ? Theme.primary : Theme.surfaceVariantText
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isEmpty
        onPressed: {
            root.isPressed = true
            if (root.isFnKey || root.isAppsKey)
                return
            if (root.isShiftKey) {
                root.shiftWasLatched = root.ydotool.shiftMode === 1
                root.ydotool.press(root.effectiveKeycode)
                if (root.ydotool.shiftMode === 0)
                    root.ydotool.shiftMode = 1
                return
            }
            root.ydotool.press(root.effectiveKeycode)
        }
        onReleased: {
            root.isPressed = false
            if (root.isFnKey) {
                root.ydotool.fnActive = !root.ydotool.fnActive
                return
            }
            if (root.isAppsKey) {
                root.ydotool.panelOpen = !root.ydotool.panelOpen
                return
            }
            if (root.isShiftKey) {
                // First tap latches Shift (one-shot, cleared by the next key);
                // tapping again releases it. No double-tap caps-lock.
                if (root.shiftWasLatched)
                    root.ydotool.releaseShiftKeys()
                return
            }
            if (root.keytype === "normal") {
                root.ydotool.release(root.effectiveKeycode)
                if (root.ydotool.shiftMode === 1)
                    root.ydotool.releaseShiftKeys()
            } else if (root.keytype === "modkey") {
                root.modToggled = !root.modToggled
                if (root.modToggled)
                    root.ydotool.retainHeld(root.keycode)
                else
                    root.ydotool.releaseHeld(root.keycode)
            }
        }
    }
}
