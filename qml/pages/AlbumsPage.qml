import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: albumsPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        try {
            if (api && api.fetchAlbumList)
                api.fetchAlbumList("alphabeticalByName");
        } catch (e) {
            console.error("AlbumsPage initialization error:", e)
        }
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
            cellWidth: 220
            cellHeight: 300
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            cacheBuffer: 2000
            displayMarginBeginning: 1000
            displayMarginEnd: 1000
            reuseItems: false
            model: (api && api.albumList) ? api.albumList : []
            delegate: Item {
                width: 220
                height: 300
                
                Components.AlbumCard {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: true
                    title: (modelData && modelData.name) ? modelData.name : "Álbum Desconhecido"
                    subtitle: (modelData && modelData.artist) ? modelData.artist : "Artista desconhecido"
                    cover: (modelData && modelData.coverArt && api) ? api.coverArtUrl(modelData.coverArt, 256) : ""
                    albumId: (modelData && modelData.id) ? modelData.id : ""
                    artistId: (modelData && modelData.artistId) ? modelData.artistId : ""
                    onClicked: {
                        if (albumsPage && modelData && modelData.id)
                            albumsPage.albumClicked(
                                modelData.id, 
                                modelData.name || "", 
                                modelData.artist || "", 
                                modelData.coverArt || "", 
                                modelData.artistId || ""
                            )
                    }
                }
            }

            property bool initialLoadComplete: false
            property real savedContentY: 0
            
            function maybeFetchMore() {
                try {
                    if (!api || !api.albumListHasMore || api.albumListLoading)
                        return;
                    if (!contentHeight || !height) return;
                    var distance = contentHeight - (contentY + height);
                    if (distance < cellHeight * 2) {
                        savedContentY = contentY
                        if (api.fetchMoreAlbums)
                            api.fetchMoreAlbums();
                    }
                } catch (e) {
                    console.warn("maybeFetchMore error:", e)
                }
            }

            onContentYChanged: { if (gridView) maybeFetchMore() }
            
            onContentHeightChanged: {
                if (gridView && initialLoadComplete && savedContentY > 0) {
                    contentY = savedContentY
                }
            }
            
            onCountChanged: {
                if (gridView && count > 0) {
                    initialLoadComplete = true
                    if (savedContentY > 0) {
                        contentY = savedContentY
                    }
                }
            }

            footer: Item {
                width: gridView.width
                height: (api && api.albumListLoading) ? 56 : 0
                BusyIndicator {
                    anchors.centerIn: parent
                    running: api && api.albumListLoading
                    visible: running
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    if (!wheel || !wheel.angleDelta) return;
                    var delta = wheel.angleDelta.y || 0
                    if (!gridView) return;
                    var newY = gridView.contentY - delta
                    var maxY = Math.max(0, gridView.contentHeight - gridView.height)
                    gridView.contentY = Math.max(0, Math.min(newY, maxY))
                }
            }
        }
    }
}

