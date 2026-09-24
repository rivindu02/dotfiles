// Gruvbox Material Dark — hand-mapped to M3 roles
// Matches SwayNC/Waybar theme: sainnhe/gruvbox-material
// Primary  : #7daea3  (blue/teal)
// Secondary: #a9b665  (green)
// Surfaces : bg0 #282828 -> bg_hard #1d2021
// Foreground: #d4be98, muted: #928374

import QtQuick

QtObject {
    id: m3

    property bool darkmode: true

    // Primary: teal/blue — active borders, focused elements
    property color m3primary:            "#7daea3"
    property color m3onPrimary:          "#181a1c"
    property color m3primaryContainer:   "#3c4a49"
    property color m3onPrimaryContainer: "#d4be98"

    // Secondary: yellow — secondary accents
    property color m3secondary:            "#d8a657"
    property color m3onSecondary:          "#181a1c"
    property color m3secondaryContainer:   "#3a3f2c"
    property color m3onSecondaryContainer: "#d4be98"

    // Backgrounds: 
    // SwayNC base background: rgba(24, 26, 28) -> #181a1c
    property color m3background:              "#181a1c"
    property color m3onBackground:            "#d4be98"

    property color m3surface:                 "#181a1c"
    // SwayNC widgets background: rgba(36, 38, 40) -> #242628
    property color m3surfaceContainerLow:     "#242628"
    // SwayNC notification background: rgba(50, 48, 47) -> #32302f
    property color m3surfaceContainer:        "#32302f"
    property color m3surfaceContainerHigh:    "#3c3836"
    property color m3surfaceContainerHighest: "#504945"

    property color m3onSurface:               "#d4be98"

    // Surface variant: subtle borders/dividers
    property color m3surfaceVariant:    "#3c3836"
    property color m3onSurfaceVariant:  "#928374"

    // Inverse: tooltips
    property color m3inverseSurface:    "#d4be98"
    property color m3inverseOnSurface:  "#181a1c"

    // Outlines: borders
    // SwayNC uses #83a598 (teal) with alpha for borders
    property color m3outline:        "#83a598"
    property color m3outlineVariant: "#83a598"

    property color m3shadow: "#000000"
}
