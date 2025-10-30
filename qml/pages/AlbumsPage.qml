import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: albumsPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId)

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchAlbumList("random");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        Label {
            text: "Álbuns"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: "#f5f7ff"
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 210
            cellHeight: 260
            model: api.albumList
            delegate: Components.AlbumCard {
                title: modelData.name || "Álbum Desconhecido"
                subtitle: modelData.artist || "Artista desconhecido"
                cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                onClicked: albumsPage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt)
            }
        }
    }
}