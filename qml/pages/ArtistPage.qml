import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: artistPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId)

    property string artistId: ""
    property string artistName: ""
    property string coverArtId: ""

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        if (artistId.length > 0)
            api.fetchArtist(artistId)
    }

    onArtistIdChanged: {
        if (artistId.length > 0)
            api.fetchArtist(artistId)
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
            width: Math.min(scrollArea.width, 960)
            x: (scrollArea.width - width) / 2
            spacing: 24
            padding: 24

                        Rectangle {
                width: contentCol.width - contentCol.padding * 2
                height: 240
                radius: 24
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#243047" }
                    GradientStop { position: 1.0; color: "#1b2233" }
                }
                border.color: "#303a52"

                Image {
                    anchors.fill: parent
                    source: api.coverArtUrl(coverArtId, 600)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.35
                    visible: !!coverArtId && status !== Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "#14171f"
                    opacity: 0.35
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 24

                                        Rectangle {
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 180
                        radius: 18
                        color: "#101321"
                        border.color: "#2b3246"
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
                            text: "🎤"
                            font.pixelSize: 48
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            text: artistName.length > 0 ? artistName : "Artista"
                            font.pixelSize: 30
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: api.albums.length + " álbuns disponíveis"
                            color: "#8b96a8"
                            font.pixelSize: 14
                        }
                        Row {
                            spacing: 12
                            ToolButton {
                                text: "▶ Aleatório"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    if (api.tracks.length > 0)
                                        player.playTrack(api.tracks[Math.floor(Math.random() * api.tracks.length)])
                                }
                            }
                            ToolButton {
                                text: "↺ Atualizar"
                                onClicked: api.fetchArtist(artistId)
                            }
                        }
                    }
                }
            }

                        Components.SectionHeader {
                width: contentCol.width - contentCol.padding * 2
                title: "Álbuns"
                subtitle: api.albums.length > 0 ? (api.albums.length + " encontrados") : ""
            }

                        Loader {
                width: contentCol.width - contentCol.padding * 2
                sourceComponent: api.albums.length === 0 ? emptyAlbums : albumFlow
            }
        }
    }

        Component {
        id: albumFlow
        Flow {
            width: parent.width
            spacing: 16
            Repeater {
                model: api.albums
                delegate: Components.AlbumCard {
                    width: 190
                    height: 240
                    title: modelData.name
                    subtitle: modelData.year > 0 ? modelData.year : ""
                    cover: api.coverArtUrl(modelData.coverArt, 300)
                    onClicked: artistPage.albumClicked(modelData.id, modelData.name, modelData.artist || artistPage.artistName, modelData.coverArt)
                }
            }
        }
    }

        Component {
        id: emptyAlbums
        Components.EmptyState {
            width: parent.width
            emoji: "📀"
            title: "Nenhum álbum encontrado"
            description: "Talvez este artista ainda esteja sincronizando. Tente atualizar."
        }
    }
}
