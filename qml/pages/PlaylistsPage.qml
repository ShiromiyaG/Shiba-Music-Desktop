import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    background: Rectangle { color: "transparent" }
    Components.ThemePalette { id: theme }

    Component.onCompleted: {
        api.fetchPlaylists()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: theme.spacing3xl

        Label {
            text: qsTr("Playlists")
            font.pixelSize: theme.fontSizeHero
            font.weight: Font.Bold
            color: theme.textPrimary
        }

        Label {
            visible: !api.playlists || api.playlists.length === 0
            text: qsTr("No playlists found")
            color: theme.textSecondary
            font.pixelSize: theme.fontSizeBody
        }

        GridView {
            id: playlistGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: theme.spacingXl
            clip: true
            cellWidth: 220
            cellHeight: 280
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            model: api.playlists
            
            ScrollBar.vertical: Components.ScrollBar {
                theme.manager: themeManager
                policy: ScrollBar.AsNeeded
                visible: playlistGrid.contentHeight > playlistGrid.height
            }
                delegate: Rectangle {
                    width: 200
                    height: 260
                    radius: theme.radiusButton
                    color: theme.cardBackground
                    border.color: theme.cardBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: theme.spacingLg
                        spacing: theme.spacingMd

                        Rectangle {
                            Layout.preferredWidth: 176
                            Layout.preferredHeight: 176
                            Layout.alignment: Qt.AlignHCenter
                            radius: theme.radiusChip
                            color: theme.surface
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
                            text: modelData.name || qsTr("Playlist")
                            font.pixelSize: theme.fontSizeBody
                            font.weight: Font.Medium
                            color: theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                        text: qsTr("%1 músicas").arg(modelData.songCount)
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeCaption
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            showPlaylistPage(modelData.id, modelData.name, modelData.coverArt, modelData.songCount)
                        }

                        ToolButton {
                            id: playBtn
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: theme.spacingMd
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
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y
                    playlistGrid.contentY = Math.max(0, Math.min(playlistGrid.contentY - delta, playlistGrid.contentHeight - playlistGrid.height))
                }
            }
        }
    }
}













