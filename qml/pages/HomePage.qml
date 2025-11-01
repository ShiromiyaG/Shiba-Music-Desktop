import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "qrc:/qml/components" as Components

Page {
    id: homePage
    objectName: "homePage"
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)
    padding: 0
    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchRandomSongs();
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: column.width
        contentHeight: column.height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: column
            width: scrollArea.width
            spacing: 24
            padding: 32

            Label {
                text: "Discover"
                font.pixelSize: 30
                font.weight: Font.DemiBold
                color: "#f5f7ff"
            }

            Label {
                text: "RECENTLY PLAYED"
                color: "#8da0c0"
                font.pixelSize: 12
                font.letterSpacing: 4
                font.weight: Font.DemiBold
            }

            Loader {
                width: column.width - column.padding * 2
                sourceComponent: api.recentlyPlayedAlbums.length > 0 ? recentlyPlayed : emptyState
            }

            Label {
                text: "MADE FOR YOU"
                color: "#8da0c0"
                font.pixelSize: 12
                font.letterSpacing: 4
                font.weight: Font.DemiBold
            }

            Loader {
                width: column.width - column.padding * 2
                sourceComponent: api.randomSongs.length > 0 ? madeForYou : emptyState
            }
        }
    }

    Component {
        id: recentlyPlayed
        Column {
            width: parent.width
            spacing: 8
            
            Item {
                id: recentWrapper
                width: parent.width
                height: 270
                clip: false

                Flickable {
                    id: recentScroll
                    anchors.fill: parent
                    clip: true
                    contentWidth: recentRow.width
                    contentHeight: recentRow.height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: false

                    Row {
                        id: recentRow
                        spacing: 16
                        Repeater {
                            model: api.recentlyPlayedAlbums
                            delegate: Components.AlbumCard {
                                title: modelData.name || "Álbum Desconhecido"
                                subtitle: modelData.artist || "Artista desconhecido"
                                cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                albumId: modelData.id
                                artistId: modelData.artistId || ""
                                onClicked: homePage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
                            }
                        }
                    }
                }
            }
            
            ScrollBar {
                id: recentScrollBar
                width: parent.width
                orientation: Qt.Horizontal
                size: recentScroll.width / recentScroll.contentWidth
                position: recentScroll.contentX / recentScroll.contentWidth
                active: true
                onPositionChanged: {
                    if (pressed) {
                        recentScroll.contentX = position * recentScroll.contentWidth
                    }
                }
            }
        }
    }

    Component {
        id: madeForYou
        Column {
            width: parent.width
            spacing: 10
            ListView {
                id: madeList
                height: contentHeight
                width: parent.width
                clip: true
                spacing: 8
                interactive: false
                model: api.randomSongs
                delegate: Rectangle {
                    property var track: modelData
                    width: madeList.width
                    height: 60
                    radius: 16
                    color: index % 2 === 0 ? "#1b2336" : "#182030"

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 18

                        Label {
                            text: "#" + (index + 1)
                            color: "#8da0c0"
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 28
                            horizontalAlignment: Text.AlignLeft
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: "#101622"
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: track.coverArt ? api.coverArtUrl(track.coverArt, 128) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: track.coverArt && status !== Image.Error
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: !track.coverArt
                                text: "♪"
                                color: "#55617b"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 200
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: track.title || "Faixa desconhecida"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: track.artist || "-"
                                color: "#8fa0c2"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Label {
                            text: track.album || "-"
                            color: "#8fa0c2"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8
                            ToolButton {
                                property bool isFavorite: track.starred || false
                                display: AbstractButton.IconOnly
                                icon.source: isFavorite ? "qrc:/qml/icons/favorite.svg" : "qrc:/qml/icons/favorite_border.svg"
                                icon.color: isFavorite ? "#ff6b6b" : "#8da0c0"
                                icon.width: 20
                                icon.height: 20
                                onClicked: {
                                    if (isFavorite) {
                                        api.unstar(track.id)
                                    } else {
                                        api.star(track.id)
                                    }
                                    isFavorite = !isFavorite
                                }
                            }
                            ToolButton {
                                text: "⋯"
                                onClicked: trackMenu.popup()
                                
                                Menu {
                                    id: trackMenu
                                    width: 200
                                    
                                    background: Rectangle {
                                        color: "#1d2330"
                                        radius: 12
                                        border.color: "#2a3040"
                                        border.width: 1
                                    }
                                    
                                    delegate: MenuItem {
                                        id: menuItem
                                        implicitWidth: 200
                                        implicitHeight: 40
                                        
                                        contentItem: Label {
                                            text: menuItem.text
                                            color: menuItem.highlighted ? "#f5f7ff" : "#b0b8c8"
                                            font.pixelSize: 13
                                            leftPadding: 16
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        background: Rectangle {
                                            color: menuItem.highlighted ? "#2a3545" : "transparent"
                                            radius: 8
                                        }
                                    }
                                    
                                    MenuItem {
                                        text: "Tocar agora"
                                        onTriggered: player.playAlbum([track], 0)
                                    }
                                    MenuItem {
                                        text: "Adicionar à fila"
                                        onTriggered: player.addToQueue(track)
                                    }
                                    MenuItem {
                                        text: "Ir para álbum"
                                        onTriggered: homePage.albumClicked(track.albumId, track.album, track.artist, track.coverArt, track.artistId || "")
                                    }
                                }
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: player.playAlbum([track], 0)
                    }
                }
            }
        }
    }

    Component {
        id: emptyState
        Components.EmptyState {
            width: parent.width
            emoji: "🎧"
            title: "Nada por aqui ainda"
            description: "Busque ou atualize sua biblioteca para preencher estas seções."
        }
    }
}
