.pragma library

// US QWERTY, compact arrangement with a right-hand navigation column
// (Home/End, PgUp, PgDn), a right Shift, and an inverted-T arrow cluster.
// Enter and backslash are the width-filling keys so the navigation column
// right-aligns. Fn latches a layer where the number row becomes F1-F12.
// Keycodes are Linux input-event-codes.

var rows = [
    [
        {keytype: "normal", label: "Esc", shape: "normal", keycode: 1},
        {keytype: "normal", label: "`", labelShift: "~", shape: "normal", keycode: 41},
        {keytype: "normal", label: "1", labelShift: "!", shape: "normal", keycode: 2, fnKeycode: 59, fnLabel: "F1"},
        {keytype: "normal", label: "2", labelShift: "@", shape: "normal", keycode: 3, fnKeycode: 60, fnLabel: "F2"},
        {keytype: "normal", label: "3", labelShift: "#", shape: "normal", keycode: 4, fnKeycode: 61, fnLabel: "F3"},
        {keytype: "normal", label: "4", labelShift: "$", shape: "normal", keycode: 5, fnKeycode: 62, fnLabel: "F4"},
        {keytype: "normal", label: "5", labelShift: "%", shape: "normal", keycode: 6, fnKeycode: 63, fnLabel: "F5"},
        {keytype: "normal", label: "6", labelShift: "^", shape: "normal", keycode: 7, fnKeycode: 64, fnLabel: "F6"},
        {keytype: "normal", label: "7", labelShift: "&", shape: "normal", keycode: 8, fnKeycode: 65, fnLabel: "F7"},
        {keytype: "normal", label: "8", labelShift: "*", shape: "normal", keycode: 9, fnKeycode: 66, fnLabel: "F8"},
        {keytype: "normal", label: "9", labelShift: "(", shape: "normal", keycode: 10, fnKeycode: 67, fnLabel: "F9"},
        {keytype: "normal", label: "0", labelShift: ")", shape: "normal", keycode: 11, fnKeycode: 68, fnLabel: "F10"},
        {keytype: "normal", label: "-", labelShift: "_", shape: "normal", keycode: 12, fnKeycode: 87, fnLabel: "F11"},
        {keytype: "normal", label: "=", labelShift: "+", shape: "normal", keycode: 13, fnKeycode: 88, fnLabel: "F12"},
        {keytype: "normal", label: "Backspace", shape: "expand", keycode: 14, shiftKeycode: 111}
    ],
    [
        {keytype: "normal", label: "Tab", shape: "tab", keycode: 15},
        {keytype: "normal", label: "q", labelShift: "Q", shape: "normal", keycode: 16},
        {keytype: "normal", label: "w", labelShift: "W", shape: "normal", keycode: 17},
        {keytype: "normal", label: "e", labelShift: "E", shape: "normal", keycode: 18},
        {keytype: "normal", label: "r", labelShift: "R", shape: "normal", keycode: 19},
        {keytype: "normal", label: "t", labelShift: "T", shape: "normal", keycode: 20},
        {keytype: "normal", label: "y", labelShift: "Y", shape: "normal", keycode: 21},
        {keytype: "normal", label: "u", labelShift: "U", shape: "normal", keycode: 22},
        {keytype: "normal", label: "i", labelShift: "I", shape: "normal", keycode: 23},
        {keytype: "normal", label: "o", labelShift: "O", shape: "normal", keycode: 24},
        {keytype: "normal", label: "p", labelShift: "P", shape: "normal", keycode: 25},
        {keytype: "normal", label: "[", labelShift: "{", shape: "normal", keycode: 26},
        {keytype: "normal", label: "]", labelShift: "}", shape: "normal", keycode: 27},
        {keytype: "normal", label: "\\", labelShift: "|", shape: "expand", keycode: 43},
        {keytype: "normal", label: "Home", shape: "normal", keycode: 102, shiftKeycode: 107, shiftLabel: "End"}
    ],
    [
        {keytype: "normal", label: "Caps", shape: "caps", keycode: 58},
        {keytype: "normal", label: "a", labelShift: "A", shape: "normal", keycode: 30},
        {keytype: "normal", label: "s", labelShift: "S", shape: "normal", keycode: 31},
        {keytype: "normal", label: "d", labelShift: "D", shape: "normal", keycode: 32},
        {keytype: "normal", label: "f", labelShift: "F", shape: "normal", keycode: 33},
        {keytype: "normal", label: "g", labelShift: "G", shape: "normal", keycode: 34},
        {keytype: "normal", label: "h", labelShift: "H", shape: "normal", keycode: 35},
        {keytype: "normal", label: "j", labelShift: "J", shape: "normal", keycode: 36},
        {keytype: "normal", label: "k", labelShift: "K", shape: "normal", keycode: 37},
        {keytype: "normal", label: "l", labelShift: "L", shape: "normal", keycode: 38},
        {keytype: "normal", label: ";", labelShift: ":", shape: "normal", keycode: 39},
        {keytype: "normal", label: "'", labelShift: "\"", shape: "normal", keycode: 40},
        {keytype: "normal", label: "Enter", shape: "expand", keycode: 28},
        {keytype: "normal", label: "PgUp", shape: "normal", keycode: 104}
    ],
    [
        {keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 42},
        {keytype: "normal", label: "z", labelShift: "Z", shape: "normal", keycode: 44},
        {keytype: "normal", label: "x", labelShift: "X", shape: "normal", keycode: 45},
        {keytype: "normal", label: "c", labelShift: "C", shape: "normal", keycode: 46},
        {keytype: "normal", label: "v", labelShift: "V", shape: "normal", keycode: 47},
        {keytype: "normal", label: "b", labelShift: "B", shape: "normal", keycode: 48},
        {keytype: "normal", label: "n", labelShift: "N", shape: "normal", keycode: 49},
        {keytype: "normal", label: "m", labelShift: "M", shape: "normal", keycode: 50},
        {keytype: "normal", label: ",", labelShift: "<", shape: "normal", keycode: 51},
        {keytype: "normal", label: ".", labelShift: ">", shape: "normal", keycode: 52},
        {keytype: "normal", label: "/", labelShift: "?", shape: "normal", keycode: 53},
        {keytype: "modkey", label: "Shift", labelShift: "Shift", labelCaps: "Caps", shape: "shift", keycode: 54},
        {keytype: "normal", label: "↑", shape: "normal", keycode: 103},
        {keytype: "normal", label: "PgDn", shape: "normal", keycode: 109}
    ],
    [
        {keytype: "modkey", label: "Ctrl", shape: "control", keycode: 29},
        {keytype: "modkey", label: "Meta", shape: "normal", keycode: 125},
        {keytype: "modkey", label: "Alt", shape: "normal", keycode: 56},
        {keytype: "normal", label: "Space", shape: "space", keycode: 57},
        {keytype: "modkey", label: "Alt", shape: "normal", keycode: 100},
        {keytype: "fnkey", label: "Fn", shape: "control"},
        {keytype: "modkey", label: "Ctrl", shape: "control", keycode: 97},
        {keytype: "normal", label: "←", shape: "normal", keycode: 105},
        {keytype: "normal", label: "↓", shape: "normal", keycode: 108},
        {keytype: "normal", label: "→", shape: "normal", keycode: 106}
    ]
];
