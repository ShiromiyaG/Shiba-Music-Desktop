import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "." as Components

Rectangle {
    id: panel
    radius: theme.isGtk ? theme.radiusCard : theme.radiusPanel
    color: theme.isMica ? Qt.tint(theme.surface, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.1)) : theme.surface
    border.color: theme.surfaceBorder
    border.width: theme.isGtk ? theme.borderWidthThin : (theme.isMica ? theme.borderWidthThin : 0)

    Components.ThemePalette { id: theme }

    readonly property var currentTrack: player && player.currentTrack ? player.currentTrack : null
    readonly property bool hasTrack: Boolean(currentTrack && currentTrack.id)
    readonly property var queueData: player && player.queue ? player.queue : []
    readonly property bool hasQueue: queueData && queueData.length > 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.isGtk ? theme.spacingXl : theme.paddingPanel
        spacing: theme.isGtk ? theme.spacingLg : theme.spacing2xl

        RowLayout {
            Layout.fillWidth: true
            spacing: theme.spacingLg
            Rectangle {
                width: 48
                height: 48
                radius: theme.isGtk ? theme.radiusChip : theme.radiusCard
                color: theme.isMica ? Qt.tint(theme.surfaceInteractive, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)) : theme.surfaceInteractive
                Components.ColoredIcon {
                    anchors.centerIn: parent
                    source: "qrc:/qml/icons/account_circle.svg"
                    width: theme.iconSizeLarge
                    height: theme.iconSizeLarge
                    smooth: true
                    color: theme.textPrimary
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: theme.spacingXs / 2
                Label {
                    text: api.username.length > 0 ? api.username : qsTr("Convidado")
                    font.pixelSize: theme.fontSizeTitle
                    font.weight: Font.Medium
                    color: theme.textPrimary
                }
                Label {
                    text: api.authenticated ? qsTr("Conectado") : qsTr("Faça login")
                    color: theme.textSecondary
                    font.pixelSize: theme.fontSizeCaption
                }
            }
        }

        Label {
            text: qsTr("Now Playing")
            font.pixelSize: theme.fontSizeTitle
            font.weight: Font.DemiBold
            color: theme.textPrimary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 220
            radius: theme.isGtk ? theme.radiusCard : theme.radiusInput
            color: theme.isMica ? Qt.tint(theme.surface, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12)) : theme.surface
            border.color: theme.surfaceBorder
            border.width: theme.isGtk ? theme.borderWidthThin : 0
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.paddingCard
                spacing: theme.spacingLg
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    radius: theme.isGtk ? theme.radiusChip : theme.radiusButton + theme.spacingXs / 2
                    color: theme.isMica ? Qt.tint(theme.surface, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12)) : theme.surface
                    clip: true
                    Image {
                        id: coverImageNowPlaying
                        anchors.fill: parent
                        source: panel.hasTrack ? api.coverArtUrl(panel.currentTrack.coverArt, 256) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: Math.min(384, width * Screen.devicePixelRatio * 1.5)
                        sourceSize.height: Math.min(384, height * Screen.devicePixelRatio * 1.5)
                    }
                    Image {
                        anchors.centerIn: parent
                        visible: coverImageNowPlaying.status !== Image.Ready
                        source: "qrc:/qml/icons/music_note.svg"
                        sourceSize.width: theme.iconSizeLarge * 1.6
                        sourceSize.height: theme.iconSizeLarge * 1.6
                        antialiasing: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.spacingXs / 2
                                        Label {
                        Layout.fillWidth: true
                        text: panel.hasTrack ? panel.currentTrack.title : qsTr("Nada tocando")
                        font.pixelSize: theme.fontSizeSubtitle
                        font.weight: Font.Medium
                        elide: Label.ElideRight
                        color: theme.textPrimary
                    }
                    Label {
                        Layout.fillWidth: true
                        text: panel.hasTrack ? panel.currentTrack.artist : qsTr("Escolha uma faixa")
                        color: theme.textSecondary
                        font.pixelSize: theme.fontSizeCaption
                        elide: Label.ElideRight
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: theme.spacingLg
            ToolButton {
                icon.source: "qrc:/qml/icons/skip_previous.svg"
                enabled: panel.hasQueue
                icon.color: theme.textPrimary
                onClicked: player.previous()
            }
            ToolButton {
                icon.source: player.playing ? "qrc:/qml/icons/pause.svg" : "qrc:/qml/icons/play_arrow.svg"
                icon.color: theme.textPrimary
                onClicked: player.toggle()
            }
            ToolButton {
                icon.source: "qrc:/qml/icons/skip_next.svg"
                enabled: panel.hasQueue
                icon.color: theme.textPrimary
                onClicked: player.next()
            }
        }

        Label {
            text: qsTr("Next tracks")
            font.pixelSize: theme.fontSizeBody
            font.weight: Font.DemiBold
            color: theme.textPrimary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentItem: ListView {
                id: queueList
                spacing: theme.spacingMd
                clip: true
                model: panel.queueData
                delegate: Rectangle {
                    width: queueList.width
                    height: 60
                    radius: theme.radiusButton
                    property bool active: panel.hasTrack && modelData.id === panel.currentTrack.id
                    color: active ? (theme.isMica ? Qt.tint(theme.listItemActive, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)) : theme.listItemActive)
                          : (theme.isMica ? Qt.rgba(theme.cardBackground.r, theme.cardBackground.g, theme.cardBackground.b, 0.9) : theme.cardBackground)
                    border.color: active ? theme.accent : theme.cardBorder
                    border.width: theme.isGtk ? theme.borderWidthThin : (active ? theme.borderWidthThin : 0)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: theme.spacingMd + theme.spacingXs / 2
                        spacing: theme.spacingLg
                        Rectangle {
                            width: 44
                            height: 44
                            radius: theme.radiusChip + theme.spacingXs / 2
                            color: theme.surface
                            clip: true
                            Image {
                                id: coverImageQueue
                                anchors.fill: parent
                                source: api.coverArtUrl(modelData.coverArt, 128)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: Math.min(256, width * Screen.devicePixelRatio * 1.5)
                                sourceSize.height: Math.min(256, height * Screen.devicePixelRatio * 1.5)
                            }
                            Image {
                                anchors.centerIn: parent
                                visible: coverImageQueue.status !== Image.Ready
                                source: "qrc:/qml/icons/music_note.svg"
                                sourceSize.width: theme.iconSizeMedium
                                sourceSize.height: theme.iconSizeMedium
                                antialiasing: true
                            }
                        }
                                               ColumnLayout {
                            Layout.fillWidth: true
                            spacing: theme.spacingXs / 2
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pixelSize: theme.fontSizeSmall
                                elide: Label.ElideRight
                                color: theme.textPrimary
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.artist
                                color: theme.textSecondary
                                font.pixelSize: theme.fontSizeExtraSmall
                                elide: Label.ElideRight
                            }
                        }
                        ToolButton {
                            icon.source: "qrc:/qml/icons/play_arrow.svg"
                            icon.color: theme.textPrimary
                            onClicked: player.playFromQueue(index)
                        }
                        ToolButton {
                            icon.source: "qrc:/qml/icons/close.svg"
                            icon.color: theme.textPrimary
                            onClicked: player.removeFromQueue(index)
                        }
                    }
                }
            }
        }
    }
}

