import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    Components.ThemePalette { id: theme }
    id: playlistPage
    property string playlistId: ""
    property string playlistName: ""
    property string coverArtId: ""
    property int songCount: 0

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.clearTracks()
        if (playlistId.length > 0)
            api.fetchPlaylist(playlistId)
    }

    onPlaylistIdChanged: {
        api.clearTracks()
        if (playlistId.length > 0)
            api.fetchPlaylist(playlistId)
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
            spacing: theme.spacing2xl
            padding: theme.paddingPanel

            Rectangle {
                width: contentCol.width - contentCol.padding * 2
                height: 200
                radius: theme.radiusPanel
                gradient: Gradient {
                    GradientStop { position: 0.0; color: theme.cardBackground }
                    GradientStop { position: 1.0; color: theme.cardBackground }
                }
                border.color: theme.surfaceInteractiveBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: theme.paddingPanel
                    spacing: theme.spacing2xl

                    Rectangle {
                        Layout.preferredWidth: 152
                        Layout.preferredHeight: 152
                        radius: theme.radiusButton
                        color: theme.surface
                        border.color: theme.surfaceInteractiveBorder
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: coverArtId ? api.coverArtUrl(coverArtId, 256) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !!coverArtId && status !== Image.Error
                        }
                        Image {
                            anchors.centerIn: parent
                            visible: !coverArtId
                            source: "qrc:/qml/icons/queue_music.svg"
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingSm
                        Label {
                            text: playlistName || qsTr("Playlist")
                            font.pixelSize: theme.fontSizePageTitle
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: qsTr("%1 músicas").arg(songCount)
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeBody
                        }
                        Row {
                            spacing: theme.spacingLg
                            ToolButton {
                                text: qsTr("Play")
                                icon.source: "qrc:/qml/icons/play_arrow.svg"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    if (api.tracks.length > 0)
                                        player.playCurrentTracks();
                                }
                            }
                            ToolButton {
                                text: qsTr("Queue")
                                icon.source: "qrc:/qml/icons/add.svg"
                                enabled: api.tracks.length > 0
                                onClicked: {
                                    for (var i = 0; i < api.tracks.length; ++i)
                                        player.addToQueue(api.tracks[i])
                                }
                            }
                        }
                    }
                }
            }

            Components.SectionHeader {
                width: contentCol.width - contentCol.padding * 2
                title: qsTr("Tracks")
                subtitle: api.tracks.length > 0 ? qsTr("%1 músicas").arg(api.tracks.length) : qsTr("Playlist vazia")
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
            spacing: theme.spacingLg
            Repeater {
                model: api.tracks
                delegate: Components.TrackRow {
                    index: index
                    width: parent.width
                    title: modelData.title
                    subtitle: modelData.artist
                    duration: modelData.duration
                    cover: api.coverArtUrl(modelData.coverArt, 128)
                    onPlayClicked: player.playTrack(modelData, index)
                    onQueueClicked: player.addToQueue(modelData)
                }
            }
        }
    }

    Component { 
        id: emptyTracks
        Components.EmptyState {
            width: parent.width
            emoji: "qrc:/qml/icons/music_note.svg"
            title: "Nenhuma faixa encontrada"
            description: qsTr("Esta playlist está vazia.")
        }
    }
}
















