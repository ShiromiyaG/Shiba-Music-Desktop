import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    width: parent.width; height: 84; color: "#121319"; border.color: "#20232b"
    RowLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 12
        Rectangle {
            width: 60; height: 60; radius: 10; color: "#111"; clip: true
            Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                    source: api.coverArtUrl(player.currentTrack.coverArt, 128) }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Label { text: player.currentTrack.title || "—"; elide: Label.ElideRight }
            Label { text: player.currentTrack.artist || ""; color: "#9aa4af"; elide: Label.ElideRight }
            Slider {
                from: 0; to: player.duration; value: player.position
                onMoved: player.seek(value)
            }
        }
        Row {
            spacing: 8
            ToolButton { text: "⏮"; onClicked: player.previous() }
            ToolButton { text: player.playing ? "⏸" : "▶"; onClicked: player.toggle() }
            ToolButton { text: "⏭"; onClicked: player.next() }
        }
    }
}
