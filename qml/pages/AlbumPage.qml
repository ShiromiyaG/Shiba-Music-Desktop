import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: albumPage
    property string albumId: ""
    property string albumTitle: ""
    property string artistName: ""
    property string coverArtId: ""

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.clearTracks()
        if (albumId.length > 0)
            api.fetchAlbum(albumId)
    }

    onAlbumIdChanged: {
        api.clearTracks()
        if (albumId.length > 0)
            api.fetchAlbum(albumId)
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

                        RowLayout {
                width: contentCol.width - contentCol.padding * 2
                spacing: 20
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.preferredHeight: 220
                    radius: 20
                    color: "#121526"
                    border.color: "#2c3550"
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: api.coverArtUrl(coverArtId, 512)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: !!coverArtId && status !== Image.Error
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !coverArtId
                        text: "📀"
                        font.pixelSize: 54
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label {
                        text: albumTitle.length > 0 ? albumTitle : "Álbum"
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        text: artistName
                        color: "#8b96a8"
                        font.pixelSize: 16
                    }
                    Row {
                        spacing: 12
                        ToolButton {
                            text: "▶ Reproduzir"
                            enabled: api.tracks.length > 0
                            onClicked: {
                                if (api.tracks.length > 0)
                                    player.playTrack(api.tracks[0])
                            }
                        }
                        ToolButton {
                            text: "➕ Fila"
                            enabled: api.tracks.length > 0
                            onClicked: {
                                for (var i = 0; i < api.tracks.length; ++i)
                                    player.addToQueue(api.tracks[i])
                            }
                        }
                    }
                }
            }

                        Components.SectionHeader {
                width: contentCol.width - contentCol.padding * 2
                title: "Faixas"
                subtitle: api.tracks.length > 0 ? (api.tracks.length + " músicas") : "Álbum vazio"
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
                    title: (modelData.track > 0 ? modelData.track + ". " : "") + modelData.title
                    subtitle: modelData.artist
                    duration: modelData.duration
                    cover: api.coverArtUrl(modelData.coverArt, 128)
                    onPlayClicked: player.playTrack(modelData)
                    onQueueClicked: player.addToQueue(modelData)
                }
            }
        }
    }

        Component { id: emptyTracks
        Components.EmptyState {
            width: parent.width
            emoji: "🎵"
            title: "Nenhuma faixa foi retornada"
            description: "Tente atualizar o álbum ou verifique sua conexão."
        }
    }
}
