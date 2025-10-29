import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: homePage
    objectName: "homePage"
    padding: 0
    background: Rectangle { color: "transparent" }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: column.width
        contentHeight: column.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: column
            width: Math.min(scrollArea.width, 1024)
            x: (scrollArea.width - width) / 2
            spacing: 24
            padding: 24

            Rectangle {
                id: hero
                width: parent.width
                height: 220
                radius: 18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2b3a55" }
                    GradientStop { position: 1.0; color: "#1f2532" }
                }
                border.color: "#3a4660"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            text: "Seja bem-vindo(a)"
                            color: "#cfd7e5"
                            font.pixelSize: 14
                        }
                        Label {
                            text: player.currentTrack.title ? player.currentTrack.title : "Descubra novas faixas hoje"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 28
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: player.currentTrack.artist ? player.currentTrack.artist : "Busque artistas, álbuns ou faixas e comece a tocar"
                            color: "#a6b0c3"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                        }
                        Row {
                            spacing: 12
                            ToolButton {
                                text: "▶ Continuar"
                                enabled: player.queue.length > 0
                                onClicked: player.toggle()
                            }
                            ToolButton {
                                text: "🔁"
                                ToolTip.visible: hovered
                                ToolTip.text: player.crossfade ? "Desativar crossfade" : "Ativar crossfade"
                                onClicked: player.crossfade = !player.crossfade
                            }
                        }
                    }
                    Rectangle {
                        width: 160; height: 160; radius: 14; color: "#111"
                        border.color: "#2f3544"
                        Image {
                            anchors.fill: parent
                            source: api.coverArtUrl(player.currentTrack.coverArt, 256)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !!player.currentTrack.coverArt && status !== Image.Error
                        }
                        Label {
                            anchors.centerIn: parent
                            visible: !player.currentTrack || !player.currentTrack.coverArt
                            text: "🎧"
                            font.pixelSize: 48
                        }
                    }
                }
            }

            Components.SectionHeader {
                title: "Artistas"
                subtitle: api.artists.length > 0 ? (api.artists.length + " na biblioteca") : ""
                ToolButton {
                    text: "Atualizar"
                    onClicked: api.fetchArtists()
                }
            }

            Loader {
                width: column.width
                sourceComponent: api.artists.length === 0 ? emptyArtists : artistFlow
            }

            Components.SectionHeader {
                title: "Faixas em destaque"
                subtitle: api.tracks.length > 0 ? (api.tracks.length + " resultados") : "Use a busca para encontrar músicas"
            }

            Loader {
                width: column.width
                sourceComponent: api.tracks.length === 0 ? emptyTracks : trackList
            }
        }
    }

    Component {
        id: artistFlow
        Flow {
            width: column.width
            spacing: 16
            Repeater {
                model: api.artists
                delegate: Components.ArtistCard {
                    width: 176
                    height: 220
                    name: modelData.name
                    cover: api.coverArtUrl(modelData.coverArt, 300)
                    onClicked: {
                        api.fetchArtist(modelData.id)
                        if (StackView.view) {
                            StackView.view.push({
                                item: Qt.resolvedUrl("qrc:/qml/pages/ArtistPage.qml"),
                                properties: {
                                    artistId: modelData.id,
                                    artistName: modelData.name,
                                    coverArtId: modelData.coverArt
                                }
                            })
                        }
                    }
                }
            }
        }
    }

    Component {
        id: trackList
        Column {
            width: column.width
            spacing: 12
            Repeater {
                model: api.tracks
                delegate: Components.TrackRow {
                    index: index
                    width: column.width
                    title: modelData.title
                    subtitle: modelData.artist + " — " + modelData.album
                    duration: modelData.duration
                    cover: api.coverArtUrl(modelData.coverArt, 128)
                    onPlayClicked: player.playTrack(modelData)
                    onQueueClicked: player.addToQueue(modelData)
                }
            }
        }
    }

    Component { id: emptyArtists
        Components.EmptyState {
            width: column.width
            title: "Nenhum artista carregado"
            description: "Faça login ou toque em atualizar para sincronizar sua biblioteca."
        }
    }

    Component { id: emptyTracks
        Components.EmptyState {
            width: column.width
            emoji: "🔍"
            title: "Faça uma busca para ouvir algo"
            description: "Digite no campo superior e pressione Enter para procurar músicas."
        }
    }
}
