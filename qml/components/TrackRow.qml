import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 640
    height: 72

    property string title
    property string subtitle
    property int duration: 0
    property url cover
    property int index: -1

    signal playClicked()
    signal queueClicked()

    function durationToText(sec) {
        var minutes = Math.floor(sec / 60)
        var seconds = sec % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: cardHovered ? "#242c3a" : "#1b2029"
        border.color: cardHovered ? "#3b465a" : "#252c36"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Label {
                text: root.index >= 0 ? root.index + 1 : ""
                visible: root.index >= 0
                width: visible ? 24 : 0
                color: "#5f6a7c"
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: 48; height: 48; radius: 8; color: "#111"; clip: true
                Image {
                    anchors.fill: parent
                    source: root.cover
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status !== Image.Error && root.cover.toString().length > 0
                }
                Label {
                    anchors.centerIn: parent
                    visible: root.cover.toString().length === 0
                    text: "♪"
                    color: "#7482a0"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: root.title
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Label.ElideRight
                }
                Label {
                    text: root.subtitle
                    elide: Label.ElideRight
                    color: "#8b96a8"
                    font.pixelSize: 12
                }
            }

            Label {
                text: durationToText(root.duration || 0)
                color: "#8b96a8"
                font.pixelSize: 12
            }

            Row {
                spacing: 6
                ToolButton {
                    text: "▶"
                    onClicked: root.playClicked()
                    ToolTip.visible: hovered
                    ToolTip.text: "Reproduzir agora"
                }
                ToolButton {
                    text: "＋"
                    onClicked: root.queueClicked()
                    ToolTip.visible: hovered
                    ToolTip.text: "Adicionar à fila"
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            acceptedDevices: PointerDevice.Mouse
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.DragThreshold
            onTapped: root.playClicked()
        }
    }

    readonly property bool cardHovered: hoverHandler.hovered
}
