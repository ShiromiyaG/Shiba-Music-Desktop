import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Item {
    id: root
    width: 200
    height: 260
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
                    
                    Image {
                        id: coverImage
                        anchors.fill: parent
                        anchors.margins: 0
                        source: root.cover
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: Math.min(512, width * Screen.devicePixelRatio * 1.5)
                        sourceSize.height: Math.min(512, height * Screen.devicePixelRatio * 1.5)
                        visible: status === Image.Ready
                    }
                    Rectangle {
                        id: fallback
                        anchors.fill: parent
                        color: "#1f2530"
                        visible: coverImage.status !== Image.Ready
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/qml/icons/album.svg"
                            sourceSize.width: 42
                            sourceSize.height: 42
                            antialiasing: true
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
            onClicked: root.clicked()

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
