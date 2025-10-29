import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: bar
    width: parent ? parent.width : 800
    height: 96
    color: "#161a22"
    border.color: "#1f2532"

    signal queueRequested()
    readonly property bool hasQueue: !!player.queue && player.queue.length > 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Rectangle {
            width: 64; height: 64; radius: 12; color: "#0f1117"; clip: true
            border.color: "#222938"
            Image {
                anchors.fill: parent
                source: api.coverArtUrl(player.currentTrack.coverArt, 128)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: !!player.currentTrack.coverArt && status !== Image.Error
            }
            Label {
                anchors.centerIn: parent
                visible: !player.currentTrack || !player.currentTrack.coverArt
                text: "♪"
                color: "#7d8aa0"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Label {
                    text: player.currentTrack.title || "Nada tocando"
                    elide: Label.ElideRight
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }
                Label {
                    text: durationToText(player.duration)
                    color: "#5f6a7c"
                    visible: player.duration > 0
                }
            }
            Label {
                text: player.currentTrack.artist || "Escolha algo para reproduzir"
                color: "#7f8aa0"
                font.pixelSize: 12
                elide: Label.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    text: durationToText(player.position)
                    color: "#5f6a7c"
                    font.pixelSize: 11
                }
                Slider {
                    id: progress
                    Layout.fillWidth: true
                    from: 0
                    to: player.duration
                    value: player.position
                    enabled: player.duration > 0
                    onMoved: player.seek(value)
                }
                Label {
                    text: durationToText(player.duration)
                    color: "#5f6a7c"
                    font.pixelSize: 11
                }
            }
        }

        Row {
            spacing: 8
            ToolButton {
                text: "⏮"
                onClicked: player.previous()
                enabled: bar.hasQueue
                ToolTip.visible: hovered
                ToolTip.text: "Anterior"
            }
            ToolButton {
                text: player.playing ? "⏸" : "▶"
                onClicked: player.toggle()
                ToolTip.visible: hovered
                ToolTip.text: player.playing ? "Pausar" : "Reproduzir"
            }
            ToolButton {
                text: "⏭"
                onClicked: player.next()
                enabled: bar.hasQueue
                ToolTip.visible: hovered
                ToolTip.text: "Próxima"
            }
            ToolButton {
                text: "🎚"
                checkable: true
                checked: player.crossfade
                onToggled: player.crossfade = checked
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Crossfade ativado" : "Crossfade desativado"
            }
            ToolButton {
                text: "📜"
                onClicked: bar.queueRequested()
                ToolTip.visible: hovered
                ToolTip.text: "Abrir fila"
            }
        }
    }

    function durationToText(ms) {
        var sec = Math.floor(ms / 1000)
        var minutes = Math.floor(sec / 60)
        var seconds = sec % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
