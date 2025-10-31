import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: playlistPage
    property string playlistId: ""
    property string playlistName: ""
    property string coverArtId: ""
    property int songCount: 0

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.clearTracks()
        if (playlistId.length > 0)
            api.fetchPlaylist(playlistId)
    }

    onPlaylistIdChanged: {
        api.clearTracks()
        if (playlistId.length > 0)
            api.fetchPlaylist(playlistId)
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: contentCol.width
        contentHeight: contentCol.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: contentCol
            width: scrollArea.width
            spacing: 20
            padding: 24

            Rectangle {
                width: contentCol.width - contentCol.padding * 2
                height: 200
                radius: 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#243047" }
                    GradientStop { position: 1.0; color: "#1b2233" }
                }
                border.color: "#303a52"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    Rectangle {
                        Layout.preferredWidth: 152
                        Layout.preferredHeight: 152
                        radius: 12
                        color: "#101321"
                        border.color: "#2b3246"
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: coverArtId ? api.coverArtUrl(coverArtId, 256) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !!coverArtId && status !== Image.Error
                        }
                        Image {
                            anchors.centerIn: parent
                            visible: !coverArtId
                            source: "qrc:/qml/icons/queue_music.svg"
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            text: playlistName || "Playlist"
                            font.pixelSize: 28
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: songCount + " músicas"
                            color: "#8b96a8"
                            font.pixelSize: 14
                        }
                        Row {
                            spacing: 12
                            ToolButton {
                                text: "Reproduzir"
                                icon.source: "qrc:/qml/icons/play_arrow.svg"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    if (api.tracks.length > 0)
                                        player.playCurrentTracks();
                                }
                            }
                            ToolButton {
                                text: "Fila"
                                icon.source: "qrc:/qml/icons/add.svg"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    for (var i = 0; i < api.tracks.length; ++i)
                                        player.addToQueue(api.tracks[i])
                                }
                            }
                        }
                    }
                }
            }

            Components.SectionHeader {
                width: contentCol.width - contentCol.padding * 2
                title: "Faixas"
                subtitle: api.tracks.length > 0 ? (api.tracks.length + " músicas") : "Playlist vazia"
            }

            Loader {
                width: contentCol.width - contentCol.padding * 2
                sourceComponent: api.tracks.length === 0 ? emptyTracks : trackList
            }
        }
    }

    Component {
        id: trackList
        Column {
            width: parent.width
            spacing: 10
            Repeater {
                model: api.tracks
                delegate: Components.TrackRow {
                    index: index
                    width: parent.width
                    title: modelData.title
                    subtitle: modelData.artist
                    duration: modelData.duration
                    cover: api.coverArtUrl(modelData.coverArt, 128)
                    onPlayClicked: player.playTrack(modelData, index)
                    onQueueClicked: player.addToQueue(modelData)
                }
            }
        }
    }

    Component { 
        id: emptyTracks
        Components.EmptyState {
            width: parent.width
            emoji: "qrc:/qml/icons/music_note.svg"
            title: "Nenhuma faixa encontrada"
            description: "Esta playlist está vazia."
        }
    }
}
