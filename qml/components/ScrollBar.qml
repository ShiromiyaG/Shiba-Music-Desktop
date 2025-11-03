import QtQuick
import QtQuick.Controls
import "." as Components

ScrollBar {
    id: control

    property alias theme: palette
    property bool micaStyle: palette && palette.isMica
    property bool gtkStyle: palette && palette.isGtk
    property bool materialStyle: palette && palette.isMaterial

    Components.ThemePalette {
        id: palette
        manager: themeManager
    }

    implicitWidth: orientation === Qt.Vertical ? (micaStyle ? 6 : 8) : 6
    implicitHeight: orientation === Qt.Horizontal ? (micaStyle ? 6 : 8) : 6

    active: true

    contentItem: Rectangle {
        width: orientation === Qt.Vertical ? control.implicitWidth : parent ? parent.width : control.width
        height: orientation === Qt.Horizontal ? control.implicitHeight : parent ? parent.height : control.height
        radius: orientation === Qt.Vertical || orientation === Qt.Horizontal ? 3 : 2
        color: micaStyle
               ? Qt.rgba(palette.accent.r, palette.accent.g, palette.accent.b, control.hovered ? 0.36 : 0.22)
               : palette.accent
        opacity: control.pressed ? 0.95 : (control.hovered ? 0.9 : 0.75)
    }

    background: Rectangle {
        anchors.fill: parent
        radius: contentItem.radius
        color: micaStyle
               ? Qt.rgba(palette.surface.r, palette.surface.g, palette.surface.b, 0.28)
               : Qt.rgba(palette.surface.r, palette.surface.g, palette.surface.b, 0.45)
    }

    function bindTheme(manager) {
        palette.manager = manager
    }
}
