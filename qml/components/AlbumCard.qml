import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 190
    height: 240
    property string title
    property string subtitle
    property url cover
    signal clicked()

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 16
        color: hoverArea.containsMouse ? "#273040" : "#1d222c"
        border.color: hoverArea.containsMouse ? "#3b465f" : "#2a303c"
        Behavior on color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                width: parent.width
                height: 150
                radius: 12
                color: "#111"
                border.color: "#2a313f"
                clip: true
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.cover
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status !== Image.Error && root.cover.toString().length > 0
                    onStatusChanged: fallback.visible = (status === Image.Error || status === Image.Null)
                }
                Rectangle {
                    id: fallback
                    anchors.fill: parent
                    color: "#1f2530"
                    visible: root.cover.toString().length === 0
                    Label {
                        anchors.centerIn: parent
                        text: root.title && root.title.length ? root.title.charAt(0) : "📀"
                        font.pixelSize: 42
                        color: "#8b96a8"
                    }
                }
            }

            Label {
                text: root.title
                font.pixelSize: 14
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }
            Label {
                text: root.subtitle
                font.pixelSize: 12
                color: "#8b96a8"
                visible: text.length > 0
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
        }
    }
}
