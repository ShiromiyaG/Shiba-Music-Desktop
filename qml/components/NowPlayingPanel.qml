import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: panel
    radius: 24
    color: "#181d2b"
    border.color: "#1f2536"

    readonly property var currentTrack: player && player.currentTrack ? player.currentTrack : null
    readonly property bool hasTrack: Boolean(currentTrack && currentTrack.id)
    readonly property var queueData: player && player.queue ? player.queue : []
    readonly property bool hasQueue: queueData && queueData.length > 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                width: 48
                height: 48
                radius: 16
                color: "#2a3145"
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qml/icons/account_circle.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    antialiasing: true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: api.username.length > 0 ? api.username : "Convidado"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                Label {
                    text: api.authenticated ? "Conectado" : "Faça login"
                    color: "#8a94ad"
                    font.pixelSize: 12
                }
            }
        }

        Label {
            text: "Tocando agora"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.fillWidth: true
            height: 220
            radius: 18
            color: "#141926"
            border.color: "#21273a"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: 14
                    color: "#0e111c"
                    clip: true
                    Image {
                        id: coverImageNowPlaying
                        anchors.fill: parent
                        source: panel.hasTrack ? api.coverArtUrl(panel.currentTrack.coverArt, 256) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Image {
                        anchors.centerIn: parent
                        visible: coverImageNowPlaying.status !== Image.Ready
                        source: "qrc:/qml/icons/music_note.svg"
                        sourceSize.width: 40
                        sourceSize.height: 40
                        antialiasing: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                                        Label {
                        Layout.fillWidth: true
                        text: panel.hasTrack ? panel.currentTrack.title : "Nada tocando"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        elide: Label.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: panel.hasTrack ? panel.currentTrack.artist : "Escolha uma faixa"
                        color: "#8b96ad"
                        font.pixelSize: 12
                        elide: Label.ElideRight
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ToolButton {
                icon.source: "qrc:/qml/icons/skip_previous.svg"
                enabled: panel.hasQueue
                onClicked: player.previous()
            }
            ToolButton {
                icon.source: player.playing ? "qrc:/qml/icons/pause.svg" : "qrc:/qml/icons/play_arrow.svg"
                onClicked: player.toggle()
            }
            ToolButton {
                icon.source: "qrc:/qml/icons/skip_next.svg"
                enabled: panel.hasQueue
                onClicked: player.next()
            }
            ToolButton {
                icon.source: player.crossfade ? "qrc:/qml/icons/auto_awesome.svg" : "qrc:/qml/icons/check_box_outline_blank.svg"
                checkable: true
                checked: player.crossfade
                onToggled: player.crossfade = checked
            }
        }

        Label {
            text: "Próximas faixas"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentItem: ListView {
                id: queueList
                spacing: 8
                clip: true
                model: panel.queueData
                delegate: Rectangle {
                    width: queueList.width
                    height: 60
                    radius: 12
                    property bool active: panel.hasTrack && modelData.id === panel.currentTrack.id
                    color: active ? "#252d40" : "#1a1f30"
                    border.color: active ? "#3a4661" : "#252c3a"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: "#10131d"
                            clip: true
                            Image {
                                id: coverImageQueue
                                anchors.fill: parent
                                source: api.coverArtUrl(modelData.coverArt, 128)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Image {
                                anchors.centerIn: parent
                                visible: coverImageQueue.status !== Image.Ready
                                source: "qrc:/qml/icons/music_note.svg"
                                sourceSize.width: 20
                                sourceSize.height: 20
                                antialiasing: true
                            }
                        }
                                                ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pixelSize: 13
                                elide: Label.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.artist
                                color: "#7e88a2"
                                font.pixelSize: 11
                                elide: Label.ElideRight
                            }
                        }
                        ToolButton {
                            icon.source: "qrc:/qml/icons/play_arrow.svg"
                            onClicked: player.playFromQueue(index)
                        }
                        ToolButton {
                            icon.source: "qrc:/qml/icons/close.svg"
                            onClicked: player.removeFromQueue(index)
                        }
                    }
                }
            }
        }
    }
}
