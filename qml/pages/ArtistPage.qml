import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "qrc:/qml/components" as Components

Page {
    id: artistPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)

    property string artistId: ""
    property string artistName: ""
    property string coverArtId: ""
    property string pendingRandomAlbumId: ""

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        coverArtId = ""
        if (artistId.length > 0)
            api.fetchArtist(artistId)
    }

    onArtistIdChanged: {
        coverArtId = ""
        if (artistId.length > 0)
            api.fetchArtist(artistId)
    }

    Connections {
        target: api
        function onArtistCoverChanged() {
            if (!artistPage.artistId.length)
                return
            if (artistPage.coverArtId !== api.artistCover) {
                artistPage.coverArtId = api.artistCover
            }
        }
        function onTracksChanged() {
            if (!artistPage.pendingRandomAlbumId.length)
                return
            if (!api.tracks || api.tracks.length === 0)
                return
            var first = api.tracks[0]
            if (!first || !first.albumId)
                return
            var fetchedAlbumId = String(first.albumId)
            if (fetchedAlbumId !== artistPage.pendingRandomAlbumId)
                return
            var index = Math.floor(Math.random() * api.tracks.length)
            var track = api.tracks[index]
            artistPage.pendingRandomAlbumId = ""
            if (track)
                player.playTrack(track)
        }
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: contentCol.width
        contentHeight: contentCol.height
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1200
        maximumFlickVelocity: 2500
        ScrollBar.vertical: ScrollBar { }
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                var delta = wheel.angleDelta.y
                scrollArea.contentY = Math.max(0, Math.min(scrollArea.contentY - delta, scrollArea.contentHeight - scrollArea.height))
            }
        }

                Column {
            id: contentCol
            width: scrollArea.width
            spacing: 24
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
                    source: (api && coverArtId) ? api.coverArtUrl(coverArtId, 600) : ""
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
                    opacity: 0.25
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
                            source: (api && coverArtId) ? api.coverArtUrl(coverArtId, 512) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !!coverArtId && status !== Image.Error
                        }
                        Image {
                            anchors.centerIn: parent
                            visible: !coverArtId
                            source: "qrc:/qml/icons/mic.svg"
                            sourceSize.width: 48
                            sourceSize.height: 48
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
                            text: (api && api.albums) ? (api.albums.length + " álbuns disponíveis") : "0 álbuns disponíveis"
                            color: "#8b96a8"
                            font.pixelSize: 14
                        }
                        Row {
                            spacing: 12
                            ToolButton {
                                text: qsTr("Shuffle")
                                icon.source: "qrc:/qml/icons/shuffle.svg"
                                enabled: api && api.albums && api.albums.length > 0
                                onClicked: {
                                    if (!api || !api.albums || api.albums.length === 0)
                                        return
                                    var idx = Math.floor(Math.random() * api.albums.length)
                                    var album = api.albums[idx]
                                    if (!album || !album.id)
                                        return
                                    artistPage.pendingRandomAlbumId = String(album.id)
                                    api.clearTracks()
                                    api.fetchAlbum(album.id)
                                }
                            }
                            ToolButton {
                                text: qsTr("Refresh")
                                icon.source: "qrc:/qml/icons/refresh.svg"
                                onClicked: api.fetchArtist(artistId)
                            }
                        }
                    }
                }
            }

                        Components.SectionHeader {
                width: contentCol.width - contentCol.padding * 2
                title: qsTr("Albums")
                subtitle: (api && api.albums && api.albums.length > 0) ? (api.albums.length + " encontrados") : ""
            }

                        Loader {
                width: contentCol.width - contentCol.padding * 2
                sourceComponent: (!api || !api.albums || api.albums.length === 0) ? emptyAlbums : albumFlow
            }
        }
    }

        Component {
        id: albumFlow
        Flow {
            width: parent.width
            spacing: 16
            Repeater {
                model: (api && api.albums) ? api.albums : []
                delegate: Components.AlbumCard {
                    width: 190
                    height: 240
                    title: modelData.name
                    subtitle: modelData.year > 0 ? modelData.year : ""
                    cover: (api && modelData.coverArt) ? api.coverArtUrl(modelData.coverArt, 300) : ""
                    albumId: modelData.id
                    artistId: modelData.artistId || artistPage.artistId
                    onClicked: artistPage.albumClicked(modelData.id, modelData.name, modelData.artist || artistPage.artistName, modelData.coverArt, modelData.artistId || artistPage.artistId)
                }
            }
        }
    }

        Component {
        id: emptyAlbums
        Components.EmptyState {
            width: parent.width
            emoji: "qrc:/qml/icons/album.svg"
            title: qsTr("No albums found")
            description: "Talvez este artista ainda esteja sincronizando. Tente atualizar."
        }
    }
}

