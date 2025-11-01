import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 176
    height: 224
    property string name
    property url cover
    property int albumCount: 0
    property string artistId: ""
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
                Layout.fillWidth: true
                Layout.preferredHeight: 150
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
                        source: "qrc:/qml/icons/mic.svg"
                        sourceSize.width: 42
                        sourceSize.height: 42
                        antialiasing: true
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2
                
                Label {
                    width: parent.width
                    text: root.name
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#f5f7ff"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    clip: true
                }
                
                Label {
                    width: parent.width
                    text: root.albumCount > 0 ? (root.albumCount + " álbun" + (root.albumCount !== 1 ? "s" : "")) : ""
                    font.pixelSize: 11
                    color: "#8fa0c2"
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.albumCount > 0
                }
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
