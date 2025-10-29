import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 600
    height: 64

    property string title
    property string subtitle
    property int duration: 0
    property url cover

    signal playClicked()
    signal queueClicked()

    Rectangle {
        anchors.fill: parent; color: "transparent"; border.color: "#252834"; radius: 8
        RowLayout {
            anchors.fill: parent; anchors.margins: 8; spacing: 12
            Rectangle {
                width: 48; height: 48; radius: 8; color: "#111"; clip: true
                Image { anchors.fill: parent; source: root.cover; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: root.title; elide: Label.ElideRight }
                Label { text: root.subtitle; color: "#9aa4af"; elide: Label.ElideRight }
            }
            Label {
                text: {
                    function fmt(sec) {
                        var m = Math.floor(sec/60); var s = sec%60;
                        return m + ":" + (s<10 ? "0"+s : s);
                    }
                    return fmt(root.duration || 0);
                }
                color: "#9aa4af"
            }
            Row {
                spacing: 8
                ToolButton { text: "▶"; onClicked: root.playClicked() }
                ToolButton { text: "+"; onClicked: root.queueClicked() }
            }
        }
    }
}
