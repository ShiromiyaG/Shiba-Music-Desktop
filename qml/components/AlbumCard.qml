import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "." as Components

Item {
    id: root
    width: 200
    height: 270
    Components.ThemePalette { id: theme }
    property string title
    property string subtitle
    property url cover
    property string albumId: ""
    property string artistId: ""
    signal clicked()
    signal playClicked()

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: 0
        radius: theme.isGtk ? theme.radiusChip : theme.radiusCard
        color: hoverArea.containsMouse ? (theme.isMica ? Qt.tint(theme.listItemHover, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)) : theme.listItemHover)
                                     : (theme.isMica ? Qt.rgba(theme.cardBackground.r, theme.cardBackground.g, theme.cardBackground.b, 0.94) : theme.cardBackground)
        border.color: hoverArea.containsMouse ? theme.surfaceInteractiveBorder : theme.cardBorder
        border.width: theme.isGtk ? theme.borderWidthThin : (theme.isMica ? theme.borderWidthThin : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
        antialiasing: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: theme.isGtk ? theme.spacingMd : theme.spacingLg
            spacing: theme.isGtk ? theme.spacingSm : theme.spacingMd

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: width
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                
                Rectangle {
                    anchors.fill: parent
                    radius: theme.isGtk ? theme.radiusBadge : theme.radiusChip
                    color: theme.surface
                    border.color: theme.cardBorder
                    border.width: theme.isGtk ? theme.borderWidthThin : 0
                    clip: true
                    antialiasing: true
                    
                    Image {
                        id: coverImage
                        anchors.fill: parent
                        anchors.margins: 0
                        source: root.cover
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true
                        sourceSize.width: 256
                        sourceSize.height: 256
                        visible: status === Image.Ready
                        
                        onStatusChanged: {
                            if (status === Image.Error) {
                                console.warn("Failed to load album cover:", root.cover, "for album:", root.title)
                            }
                        }
                    }
                    
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: coverImage.status === Image.Loading
                        visible: running
                        width: 40
                        height: 40
                    }
                    
                    Rectangle {
                        id: fallback
                        anchors.fill: parent
                        color: theme.surface
                        visible: coverImage.status !== Image.Ready && coverImage.status !== Image.Loading
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/qml/icons/album.svg"
                            sourceSize.width: theme.iconSizeLarge * 1.75
                            sourceSize.height: theme.iconSizeLarge * 1.75
                            antialiasing: true
                            smooth: true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: theme.spacingXs

                Label {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: theme.fontSizeBody
                    font.weight: Font.Medium
                    color: theme.textPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
                Label {
                    Layout.fillWidth: true
                    text: root.subtitle
                    font.pixelSize: theme.fontSizeCaption
                    color: theme.textSecondary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text.length > 0
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 0
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    root.clicked()
                } else if (mouse.button === Qt.RightButton) {
                    contextMenu.popup()
                }
            }

            property string pendingPlayAlbumId: ""
            property string pendingQueueAlbumId: ""
            
            Connections {
                target: api
                function onTracksChanged() {
                    if (hoverArea.pendingPlayAlbumId.length > 0 && api.tracks.length > 0) {
                        player.playCurrentTracks(0)
                        hoverArea.pendingPlayAlbumId = ""
                    }
                    if (hoverArea.pendingQueueAlbumId.length > 0 && api.tracks.length > 0) {
                        for (var i = 0; i < api.tracks.length; i++) {
                            player.addToQueue(api.tracks[i])
                        }
                        hoverArea.pendingQueueAlbumId = ""
                    }
                }
            }
            
            Menu {
                id: contextMenu
                width: 200
                
                background: Rectangle {
                    color: theme.cardBackground
                    radius: theme.radiusButton
                    border.color: theme.cardBorder
                    border.width: theme.borderWidthThin
                }
                
                delegate: MenuItem {
                    id: menuItem
                    implicitWidth: 200
                    implicitHeight: 40
                    
                    contentItem: Label {
                        text: menuItem.text
                        color: menuItem.highlighted ? theme.textPrimary : theme.textSecondary
                        font.pixelSize: theme.fontSizeSmall
                        leftPadding: theme.spacingXl
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: menuItem.highlighted ? theme.listItemHover : "transparent"
                        radius: theme.radiusChip
                    }
                }
                
                MenuItem {
                    text: qsTr("Play Album")
                    enabled: albumId.length > 0
                    onTriggered: {
                        hoverArea.pendingPlayAlbumId = albumId
                        api.fetchAlbum(albumId)
                    }
                }
                MenuItem {
                    text: qsTr("Add to Queue")
                    enabled: albumId.length > 0
                    onTriggered: {
                        hoverArea.pendingQueueAlbumId = albumId
                        api.fetchAlbum(albumId)
                    }
                }
                MenuSeparator {
                    contentItem: Rectangle {
                        implicitHeight: theme.borderWidthThin
                        color: theme.cardBorder
                    }
                }
                MenuItem {
                    text: qsTr("Go to Artist")
                    enabled: artistId.length > 0
                    onTriggered: {
                        if (artistId.length > 0)
                            showArtistPage(artistId, root.subtitle, "")
                    }
                }
            }

            ToolButton {
                id: playBtn
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.spacingMd
                icon.source: "qrc:/qml/icons/play_arrow.svg"
                visible: hoverArea.containsMouse && albumId.length > 0
                property string pendingAlbumId: ""
                
                Connections {
                    target: api
                    function onTracksChanged() {
                        if (playBtn.pendingAlbumId.length > 0 && api.tracks.length > 0) {
                            player.playCurrentTracks()
                            playBtn.pendingAlbumId = ""
                        }
                    }
                }
                
                onClicked: {
                    pendingAlbumId = albumId
                    api.fetchAlbum(albumId)
                }
            }
        }
    }
}
