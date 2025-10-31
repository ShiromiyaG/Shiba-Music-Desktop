import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 200
    height: 260
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
                Layout.preferredWidth: 176
                Layout.preferredHeight: 176
                radius: 0
                color: "#111"
                border.color: "#2a313f"
                clip: true
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.cover
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }
                Rectangle {
                    id: fallback
                    anchors.fill: parent
                    color: "#1f2530"
                    visible: coverImage.status !== Image.Ready
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qml/icons/album.svg"
                        sourceSize.width: 42
                        sourceSize.height: 42
                        antialiasing: true
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 14
                font.weight: Font.Medium
                color: "#f5f7ff"
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
            }
            Label {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: 12
                color: "#8b96a8"
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text.length > 0
            }

            Item {
                Layout.fillHeight: true
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
