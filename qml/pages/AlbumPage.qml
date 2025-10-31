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
    property string artistId: ""

    function requestArtistPage() {
        var id = artistId
        var name = artistName
        if ((!id || id.length === 0) && api.tracks.length > 0) {
            var first = api.tracks[0]
            if (first.albumId === albumId) {
                id = first.artistId || id
                if (!name || name.length === 0)
                    name = first.artist || name
            }
        }
        if (id && id.length > 0)
            StackView.view.push(Qt.resolvedUrl("qrc:/qml/pages/ArtistPage.qml"), {
                artistId: id,
                artistName: name,
                coverArtId: coverArtId
            })
    }

    function refreshArtistMetadata() {
        if (api.tracks.length === 0)
            return
        var firstTrack = api.tracks[0]
        if (firstTrack.albumId !== albumId)
            return
        if (!artistId || artistId.length === 0)
            artistId = firstTrack.artistId || ""
        if ((!artistName || artistName.length === 0) && firstTrack.artist)
            artistName = firstTrack.artist
    }

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.clearTracks()
        artistId = ""
        if (albumId.length > 0)
            api.fetchAlbum(albumId)
    }

    onAlbumIdChanged: {
        api.clearTracks()
        artistId = ""
        if (albumId.length > 0)
            api.fetchAlbum(albumId)
    }

    Connections {
        target: api
        function onTracksChanged() {
            if (!albumPage.visible)
                return
            refreshArtistMetadata()
        }
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
                        Item {
                            id: artistLink
                            property bool hovered: false
                            property bool enabled: (!!artistId && artistId.length > 0) || (api.tracks.length > 0 && api.tracks[0].albumId === albumId)
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredWidth: artistText.implicitWidth
                            Layout.preferredHeight: artistText.implicitHeight

                            Text {
                                id: artistText
                                text: artistName
                                font.pixelSize: 14
                                color: (artistLink.hovered && artistLink.enabled) ? "#c5d2ff" : "#8b96a8"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: artistLink.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: artistLink.hovered = true
                                onExited: artistLink.hovered = false
                                onClicked: if (artistLink.enabled) requestArtistPage()
                            }
                        }
                        Row {
                            spacing: 12
                            ToolButton {
                                text: "Reproduzir"
                                icon.source: "qrc:/qml/icons/play_arrow.svg"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    if (api.tracks.length > 0)
                                        player.playCurrentTracks();
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
                            ToolButton {
                                text: "Opções"
                                icon.source: "qrc:/qml/icons/settings.svg"
                                onClicked: albumMenu.open()
                                
                                Menu {
                                    id: albumMenu
                                    y: parent.height
                                    
                                    MenuItem {
                                        text: "Reproduzir Aleatório"
                                        icon.source: "qrc:/qml/icons/shuffle.svg"
                                        enabled: api.tracks.length > 0
                                        onTriggered: {
                                            var shuffled = api.tracks.slice()
                                            for (var i = shuffled.length - 1; i > 0; i--) {
                                                var j = Math.floor(Math.random() * (i + 1))
                                                var temp = shuffled[i]
                                                shuffled[i] = shuffled[j]
                                                shuffled[j] = temp
                                            }
                                            player.clearQueue()
                                            for (var k = 0; k < shuffled.length; k++)
                                                player.addToQueue(shuffled[k])
                                            player.playCurrentTracks()
                                        }
                                    }
                                    MenuItem {
                                        text: "Adicionar à Playlist"
                                        icon.source: "qrc:/qml/icons/add.svg"
                                        enabled: api.tracks.length > 0
                                        onTriggered: console.log("Adicionar à playlist")
                                    }
                                    MenuItem {
                                        text: "Adicionar aos Favoritos"
                                        icon.source: "qrc:/qml/icons/favorite_border.svg"
                                        enabled: api.tracks.length > 0
                                        onTriggered: {
                                            for (var i = 0; i < api.tracks.length; i++) {
                                                api.star(api.tracks[i].id, "song")
                                            }
                                        }
                                    }
                                    MenuSeparator { }
                                    MenuItem {
                                        text: "Ir para Artista"
                                        icon.source: "qrc:/qml/icons/mic.svg"
                                        enabled: artistName.length > 0 && api.tracks.length > 0
                                        onTriggered: requestArtistPage()
                                    }
                                    MenuItem {
                                        text: "Informações do Álbum"
                                        icon.source: "qrc:/qml/icons/album.svg"
                                        onTriggered: albumInfoDialog.open()
                                    }
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
                    onPlayClicked: player.playTrack(modelData, index)
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

    Dialog {
        id: albumInfoDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(500, parent.width - 40)
        modal: true
        
        Overlay.modal: Rectangle {
            color: "#cc000000"
        }
        
        background: Rectangle {
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#243047" }
                GradientStop { position: 1.0; color: "#1b2233" }
            }
            radius: 16
        }
        
        header: Label {
            text: "Informações do Álbum"
            font.pixelSize: 18
            font.weight: Font.DemiBold
            padding: 20
            bottomPadding: 10
        }
        
        contentItem: ColumnLayout {
            spacing: 12
            
            Label {
                text: "<b>Título:</b> " + albumTitle
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Label {
                text: "<b>Artista:</b> " + artistName
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Label {
                text: "<b>Faixas:</b> " + api.tracks.length
                Layout.fillWidth: true
            }
            Label {
                text: "<b>ID:</b> " + albumId
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 11
                color: "#8b96a8"
            }
        }
        
        footer: DialogButtonBox {
            background: Rectangle { color: "transparent" }
            padding: 20
            topPadding: 10
            Button {
                text: "Fechar"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
        }
    }
}
