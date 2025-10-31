import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchPlaylists()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 24

        Label {
            text: "Playlists"
            font.pixelSize: 32
            font.weight: Font.Bold
            color: "#f5f7ff"
        }

        Label {
            visible: !api.playlists || api.playlists.length === 0
            text: "Nenhuma playlist encontrada"
            color: "#a0aac6"
            font.pixelSize: 14
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridView {
                cellWidth: 220
                cellHeight: 280
                model: api.playlists
                delegate: Rectangle {
                    width: 200
                    height: 260
                    radius: 12
                    color: "#1b2336"
                    border.color: "#252e42"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 176
                            Layout.preferredHeight: 176
                            Layout.alignment: Qt.AlignHCenter
                            radius: 8
                            color: "#101622"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Image {
                                anchors.centerIn: parent
                                visible: !modelData.coverArt
                                source: "qrc:/qml/icons/queue_music.svg"
                                sourceSize.width: 64
                                sourceSize.height: 64
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.name || "Playlist"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#f5f7ff"
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.songCount + " músicas"
                            color: "#8fa0c2"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            showPlaylistPage(modelData.id, modelData.name, modelData.coverArt, modelData.songCount)
                        }

                        ToolButton {
                            id: playBtn
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            icon.source: "qrc:/qml/icons/play_arrow.svg"
                            property string pendingPlaylistId: ""
                            
                            Connections {
                                target: api
                                function onTracksChanged() {
                                    if (playBtn.pendingPlaylistId.length > 0 && api.tracks.length > 0) {
                                        player.playCurrentTracks()
                                        playBtn.pendingPlaylistId = ""
                                    }
                                }
                            }
                            
                            onClicked: {
                                pendingPlaylistId = modelData.id
                                api.fetchPlaylist(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
