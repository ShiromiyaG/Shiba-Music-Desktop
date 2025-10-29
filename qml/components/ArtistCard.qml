import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 176
    height: 224
    property string name
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
                        text: root.name && root.name.length ? root.name.charAt(0) : "🎤"
                        font.pixelSize: 42
                        color: "#8b96a8"
                    }
                }
            }

            Label {
                text: root.name
                font.pixelSize: 14
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
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
