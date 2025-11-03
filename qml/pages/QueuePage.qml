import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components" as Components

Item {
    Components.ThemePalette { id: theme }
    id: queuePage
    signal closeRequested()

    Rectangle {
        id: queueContent
        width: parent.width
        height: parent.height
        color: theme.shadow
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
            radius: theme.radiusQueueHero
        }

        Rectangle {
            anchors.fill: parent
            color: theme.shadow
            opacity: 0.7
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.paddingPage * 2
            spacing: theme.spacing4xl

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
                    color: theme.surface
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
                spacing: theme.spacingXl

                Label {
                    text: qsTr("Playback Queue")
                    font.pixelSize: theme.fontSizeHero
                    font.weight: Font.Bold
                    color: theme.textPrimary
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        model: player.queue
                        spacing: theme.spacingMd
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 64
                            radius: theme.radiusChip
                            color: index === player.currentIndex ? theme.listItemActive : (queueHover.hovered ? theme.listItemHover : theme.cardBackground)
                            border.color: index === player.currentIndex ? theme.surfaceInteractiveBorder : (queueHover.hovered ? theme.surfaceInteractiveBorder : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            HoverHandler {
                                id: queueHover
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: theme.spacingLg
                                spacing: theme.spacingLg

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    color: theme.surface

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 128) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: theme.spacingXs

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title || qsTr("Faixa desconhecida")
                                        font.pixelSize: theme.fontSizeBody
                                        font.weight: Font.Medium
                                        color: theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.artist || "-"
                                        color: theme.textMuted
                                        font.pixelSize: theme.fontSizeCaption
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
            anchors.margins: theme.paddingPanel
            icon.source: "qrc:/qml/icons/close.svg"
            z: 10
            onClicked: queueContent.slideOut()
        }
    }
}













