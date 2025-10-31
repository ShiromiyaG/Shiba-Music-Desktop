import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: queuePage
    signal closeRequested()

    Rectangle {
        id: queueContent
        width: parent.width
        height: parent.height
        color: "#000000"
        y: 0

        Component.onCompleted: {
            y = parent.height
            slideInAnim.start()
        }

        NumberAnimation {
            id: slideInAnim
            target: queueContent
            property: "y"
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: slideOutAnim
            target: queueContent
            property: "y"
            to: queuePage.height
            duration: 300
            easing.type: Easing.InCubic
            onFinished: queuePage.closeRequested()
        }

        function slideOut() {
            slideOutAnim.start()
        }

        Image {
            id: bgImage
            anchors.fill: parent
            source: player.currentTrack && player.currentTrack.coverArt ? api.coverArtUrl(player.currentTrack.coverArt, 1024) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        FastBlur {
            anchors.fill: bgImage
            source: bgImage
            radius: 80
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.7
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 64
            spacing: 64

            Item {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
            }

            Item {
                Layout.preferredWidth: 500
                Layout.fillHeight: true
                
                Rectangle {
                    width: 500
                    height: 500
                    anchors.centerIn: parent
                    color: "#1a1a1a"
                    border.color: "#333"
                    border.width: 2

                    Image {
                        anchors.fill: parent
                        source: player.currentTrack && player.currentTrack.coverArt ? api.coverArtUrl(player.currentTrack.coverArt, 512) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Label {
                    text: "Fila de reprodução"
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    color: "#ffffff"
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        model: player.queue
                        spacing: 8
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 64
                            radius: 8
                            color: index === player.currentIndex ? "#3a3a3a" : "#2a2a2a"
                            border.color: index === player.currentIndex ? "#5a5a5a" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    color: "#1a1a1a"

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 128) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Faixa desconhecida"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.artist || "-"
                                        color: "#aaaaaa"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                ToolButton {
                                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                                    onClicked: player.playFromQueue(index)
                                }

                                ToolButton {
                                    icon.source: "qrc:/qml/icons/close.svg"
                                    onClicked: player.removeFromQueue(index)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: player.playFromQueue(index)
                            }
                        }
                    }
                }
            }
        }

        RoundButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 24
            icon.source: "qrc:/qml/icons/close.svg"
            z: 10
            onClicked: queueContent.slideOut()
        }
    }
}
