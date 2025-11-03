import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property url source: ""
    property color color: "#ffffff"
    property bool smooth: true
    property bool asynchronous: true
    property real size: 24

    implicitWidth: size
    implicitHeight: size

    Image {
        id: base
        anchors.fill: parent
        source: root.source
        smooth: root.smooth
        asynchronous: root.asynchronous
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        anchors.fill: parent
        source: base
        color: root.color
    }
}
