pragma Singleton
import QtQuick

QtObject {
    readonly property int wheelScrollLines: 3
    readonly property real flickDeceleration: 1200
    readonly property real maximumFlickVelocity: 2500
}
