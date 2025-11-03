import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "qrc:/qml/components" as Components

Page {
    Components.ThemePalette { id: theme }
    id: artistPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)

    property string artistId: ""
    property string artistName: ""
    property string coverArtId: ""
    property string pendingRandomAlbumId: ""

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        if (artistId.length > 0)
            api.fetchArtist(artistId)
    }

    StackView.onStatusChanged: {
        if (StackView.status === StackView.Deactivating) {
            pendingRandomAlbumId = ""
        }
    }

    onArtistIdChanged: {
        if (artistId.length > 0)
            api.fetchArtist(artistId)
    }

    Connections {
        target: api
        function onArtistCoverChanged() {
            if (artistPage.StackView.status !== StackView.Active)
                return
            if (!artistPage.artistId.length)
                return
            if (artistPage.coverArtId !== api.artistCover) {
                artistPage.coverArtId = api.artistCover
            }
        }
        function onTracksChanged() {
            if (artistPage.StackView.status !== StackView.Active)
                return
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
    ScrollBar.vertical: Components.ScrollBar { theme.manager: themeManager }
        
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
            spacing: theme.spacing3xl
            padding: theme.paddingPage

                        Rectangle {
                width: contentCol.width - contentCol.padding * 2
                height: 240
                radius: theme.radiusPanel
                gradient: Gradient {
                    GradientStop { position: 0.0; color: theme.cardBackground }
                    GradientStop { position: 1.0; color: theme.cardBackground }
                }
                border.color: theme.surfaceInteractiveBorder
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
                        radius: theme.radiusPanel
                    }
                    opacity: 0.25
                    visible: !!coverArtId && bgImage.status !== Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    radius: theme.radiusPanel
                    color: theme.windowBackgroundStart
                    opacity: 0.35
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: theme.paddingPanel
                    spacing: theme.spacing3xl

                                        Rectangle {
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 180
                        radius: theme.radiusCard
                        color: theme.surface
                        border.color: theme.surfaceInteractiveBorder
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
                        spacing: theme.spacingSm
                        Label {
                            text: artistName.length > 0 ? artistName : "Artista"
                              font.pixelSize: theme.fontSizeHeroTitle
                              font.weight: Font.DemiBold
                              font.family: theme.fontFamily
                        }
                        Label {
                            text: (api && api.albums && api.albums.length > 0)
                              ? qsTr("%1 álbuns disponíveis").arg(api.albums.length)
                              : qsTr("0 álbuns disponíveis")
                              color: theme.textSecondary
                              font.pixelSize: theme.fontSizeBody
                              font.family: theme.fontFamily
                        }
                          Row {
                            spacing: theme.spacingLg
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
            width: parent ? parent.width : 0
            spacing: theme.spacingXl
            
            Repeater {
                model: (api && api.albums) ? api.albums : []
                delegate: Components.AlbumCard {
                    width: 180
                    height: 250
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
            description: qsTr("Talvez este artista ainda esteja sincronizando. Tente atualizar.")
        }
    }
}














