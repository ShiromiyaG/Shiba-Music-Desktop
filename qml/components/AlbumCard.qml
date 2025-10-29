import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root; width: 170; height: 230
    property string title
    property string subtitle
    property url cover
    signal clicked()

    Rectangle {
        anchors.fill: parent; radius: 12; color: "#222429"
        Column {
            anchors.fill: parent; anchors.margins: 8; spacing: 8
            Rectangle {
                width: parent.width; height: 150; radius: 10; color: "#111"; clip: true
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.cover
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    onStatusChanged: fallback.visible = (status === Image.Error || status === Image.Null)
                }
                Rectangle {
                    id: fallback
                    anchors.fill: parent
                    color: "#333"
                    visible: false
                    Label {
                        anchors.centerIn: parent
                        text: root.title && root.title.length ? root.title.charAt(0) : "?"
                        font.pixelSize: 48
                        color: "#8892a0"
                    }
                }
            }
            Label { text: root.title; elide: Label.ElideRight }
            Label { text: root.subtitle; color: "#9aa4af"; elide: Label.ElideRight }
        }
        MouseArea { anchors.fill: parent; onClicked: root.clicked() }
    }
}
