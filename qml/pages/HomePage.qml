import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: homePage
    objectName: "homePage"
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId)
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
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: column
            width: Math.min(scrollArea.width, 1024)
            x: (scrollArea.width - width) / 2
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
                width: column.width
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
                width: column.width
                sourceComponent: api.randomSongs.length > 0 ? madeForYou : emptyState
            }
        }
    }

    Component {
        id: recentlyPlayed
        Flow {
            id: recentFlow
            width: column.width
            height: childrenRect.height
            spacing: 20
            property real cardWidth: Math.min(width / 4 - spacing, 220)
            Repeater {
                model: api.recentlyPlayedAlbums
                delegate: Rectangle {
                    property var album: modelData
                    width: recentFlow.cardWidth
                    height: 220
                    radius: 20
                    color: "#20293f"
                    border.color: "#2c3752"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: 16
                            color: "#12182a"
                            Image {
                                anchors.fill: parent
                                source: album.coverArt ? api.coverArtUrl(album.coverArt, 320) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: album.coverArt && status !== Image.Error
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: !album.coverArt
                                text: "💿"
                                font.pixelSize: 40
                                color: "#5e6d8d"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Label {
                                text: album.name || "Album desconhecido"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                elide: Label.ElideRight
                            }
                            Label {
                                text: album.artist || "Artista desconhecido"
                                color: "#8fa0c2"
                                font.pixelSize: 12
                                elide: Label.ElideRight
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: homePage.albumClicked(album.id, album.name, album.artist, album.coverArt)
                    }
                }
            }
        }
    }

    Component {
        id: madeForYou
        Column {
            width: column.width
            spacing: 10
            ListView {
                id: madeList
                height: contentHeight
                width: column.width
                clip: true
                spacing: 8
                interactive: false
                model: api.randomSongs
                delegate: Rectangle {
                    property var track: modelData
                    width: (madeList.view ? madeList.view.width : madeList.width)
                    height: 60
                    radius: 16
                    color: index % 2 === 0 ? "#1b2336" : "#182030"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 18

                        Label {
                            text: "#" + (index + 1)
                            color: "#8da0c0"
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                            width: 28
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            radius: 12
                            color: "#101622"
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
                            spacing: 2
                            Label {
                                text: track.title || "Faixa desconhecida"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Label.ElideRight
                            }
                            Label {
                                text: track.artist || "-"
                                color: "#8fa0c2"
                                font.pixelSize: 12
                                elide: Label.ElideRight
                            }
                        }

                        Label {
                            text: track.album || "-"
                            color: "#8fa0c2"
                            font.pixelSize: 12
                            Layout.preferredWidth: 180
                            elide: Label.ElideRight
                        }

                        RowLayout {
                            spacing: 8
                            ToolButton {
                                text: "❤"
                                onClicked: player.addToQueue(track)
                            }
                            ToolButton {
                                text: "⋯"
                                onClicked: player.playTrack(track)
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: player.playTrack(track)
                    }
                }
            }
        }
    }

    Component {
        id: emptyState
        Components.EmptyState {
            width: column.width
            emoji: "🎧"
            title: "Nada por aqui ainda"
            description: "Busque ou atualize sua biblioteca para preencher estas seções."
        }
    }
}
