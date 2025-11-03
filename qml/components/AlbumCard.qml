import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Item {
    id: root
    width: 200
    height: 270
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
        radius: 16
        color: hoverArea.containsMouse ? "#273040" : "#1d222c"
        border.color: hoverArea.containsMouse ? "#3b465f" : "#2a303c"
        Behavior on color { ColorAnimation { duration: 120 } }
        antialiasing: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: width
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "#111"
                    border.color: "#2a313f"
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
                        color: "#1f2530"
                        visible: coverImage.status !== Image.Ready && coverImage.status !== Image.Loading
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/qml/icons/album.svg"
                            sourceSize.width: 42
                            sourceSize.height: 42
                            antialiasing: true
                            smooth: true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 4

                Label {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#f5f7ff"
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
                Label {
                    Layout.fillWidth: true
                    text: root.subtitle
                    font.pixelSize: 12
                    color: "#8b96a8"
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
                        implicitHeight: 1
                        color: "#2a3040"
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
                anchors.margins: 8
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
