import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: albumsPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchAlbumList("random");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 18

        Label {
            text: qsTr("Albums")
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: "#f5f7ff"
            Layout.leftMargin: 32
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 210
            cellHeight: 260
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            model: api.albumList
            delegate: Components.AlbumCard {
                title: modelData.name || "Álbum Desconhecido"
                subtitle: modelData.artist || "Artista desconhecido"
                cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                albumId: modelData.id
                artistId: modelData.artistId || ""
                onClicked: albumsPage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
            }

            function maybeFetchMore() {
                if (!api.albumListHasMore || api.albumListLoading)
                    return;
                var distance = contentHeight - (contentY + height);
                if (distance < cellHeight * 2 || contentHeight <= height) {
                    api.fetchMoreAlbums();
                }
            }

            onContentYChanged: maybeFetchMore()
            onContentHeightChanged: maybeFetchMore()
            onCountChanged: maybeFetchMore()

            footer: Item {
                width: gridView.width
                height: api.albumListLoading ? 56 : 0
                BusyIndicator {
                    anchors.centerIn: parent
                    running: api.albumListLoading
                    visible: running
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y
                    gridView.contentY = Math.max(0, Math.min(gridView.contentY - delta, gridView.contentHeight - gridView.height))
                }
            }
        }
    }
}

