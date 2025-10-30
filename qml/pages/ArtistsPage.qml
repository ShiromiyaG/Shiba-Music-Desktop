import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: artistsPage
    signal artistClicked(string artistId, string artistName, string coverArtId)

    background: Rectangle { color: "transparent" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        Label {
            text: "Artistas"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: "#f5f7ff"
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 196
            cellHeight: 244
            model: api.artists
            delegate: Components.ArtistCard {
                name: modelData.name || "Artista Desconhecido"
                cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                onClicked: artistsPage.artistClicked(modelData.id, modelData.name, modelData.coverArt)
            }
        }
    }
}