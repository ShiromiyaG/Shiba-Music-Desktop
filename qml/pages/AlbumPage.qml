import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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

                        Rectangle {
                width: contentCol.width - contentCol.padding * 2
                height: 240
                radius: 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#243047" }
                    GradientStop { position: 1.0; color: "#1b2233" }
                }
                border.color: "#303a52"
                clip: true

                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: api.coverArtUrl(coverArtId, 600)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: bgImage
                    source: bgImage
                    maskSource: Rectangle {
                        width: bgImage.width
                        height: bgImage.height
                        radius: 24
                    }
                    opacity: 0.15
                    visible: !!coverArtId && bgImage.status !== Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: "#14171f"
                    opacity: 0.35
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

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
                        Image {
                            anchors.centerIn: parent
                            visible: !coverArtId
                            source: "qrc:/qml/icons/album.svg"
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            text: albumTitle.length > 0 ? albumTitle : "Álbum"
                            font.pixelSize: 30
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: artistName
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
                                        player.playTrack(api.tracks[0])
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
            emoji: "qrc:/qml/icons/music_note.svg"
            title: "Nenhuma faixa foi retornada"
            description: "Tente atualizar o álbum ou verifique sua conexão."
        }
    }
}
