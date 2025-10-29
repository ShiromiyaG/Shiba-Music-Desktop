import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: homePage
    padding: 16

    contentItem: Flickable {
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: 16

            Label {
                text: "Artistas"
                font.pixelSize: 18
                padding: 8
            }

            GridView {
                id: artistsGrid
                anchors.left: parent.left
                anchors.right: parent.right
                cellWidth: 160
                cellHeight: 220
                height: 480
                model: api.artists
                delegate: Components.ArtistCard {
                    name: modelData.name
                    cover: api.coverArtUrl(modelData.coverArt, 300)
                    onClicked: {
                        api.fetchArtist(modelData.id)
                        StackView.view.push("qrc:/qml/pages/ArtistPage.qml")
                    }
                }
            }

            Label {
                text: "Resultados de Busca / Faixas"
                font.pixelSize: 18
                padding: 8
            }
            ListView {
                height: 320
                model: api.tracks
                delegate: Components.TrackRow {
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
}
