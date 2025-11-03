import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/js/utils.js" as Utils
import "." as Components

Item {
    id: root
    width: parent ? parent.width : 640
    height: 72

    Components.ThemePalette { id: theme }

    property string title
    property string subtitle
    property int duration: 0
    property url cover
    property int index: -1
    property string trackId: ""
    property bool starred: false

    signal playClicked()
    signal queueClicked()

    Rectangle {
        id: card
        anchors.fill: parent
        radius: theme.isGtk ? theme.radiusChip : theme.radiusCard
        color: cardHovered ? (theme.isMica ? Qt.tint(theme.listItemHover, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)) : theme.listItemHover)
                             : (theme.isMica ? Qt.rgba(theme.cardBackground.r, theme.cardBackground.g, theme.cardBackground.b, 0.92) : theme.cardBackground)
        border.color: cardHovered ? theme.surfaceInteractiveBorder : theme.cardBorder
        border.width: theme.isGtk ? theme.borderWidthThin : (theme.isMica ? theme.borderWidthThin : 0)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.isGtk ? theme.spacingMd : theme.spacingLg
            spacing: theme.isGtk ? theme.spacingMd : theme.spacingLg

            Label {
                text: root.index >= 0 ? root.index + 1 : ""
                visible: root.index >= 0
                Layout.preferredWidth: visible ? 28 : 0
                color: theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: theme.fontSizeSmall
            }

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: theme.isGtk ? theme.radiusBadge : theme.radiusChip
                color: theme.surface
                clip: true
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.cover
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Image {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready
                    source: "qrc:/qml/icons/music_note.svg"
                    sourceSize.width: theme.iconSizeMedium
                    sourceSize.height: theme.iconSizeMedium
                    antialiasing: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: theme.isGtk ? theme.spacingXs : theme.spacingXs / 2
                Label {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: theme.fontSizeBody
                    font.weight: Font.Medium
                    elide: Label.ElideRight
                    color: theme.textPrimary
                }
                Label {
                    Layout.fillWidth: true
                    text: root.subtitle
                    elide: Label.ElideRight
                    color: theme.textSecondary
                    font.pixelSize: theme.fontSizeCaption
                }
            }

            Label {
                text: Utils.durationToText(root.duration || 0)
                color: theme.textSecondary
                font.pixelSize: theme.isGtk ? theme.fontSizeSmall : theme.fontSizeCaption
            }

            Row {
                spacing: theme.isGtk ? theme.spacingXs : theme.spacingSm
                ToolButton {
                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                    flat: theme.isGtk
                    onClicked: root.playClicked()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Play now")
                }
                ToolButton {
                    text: "⋯"
                    flat: theme.isGtk
                    onClicked: trackMenu.popup()
                    
                    Menu {
                        id: trackMenu
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
                                border.width: theme.isGtk ? theme.borderWidthThin : 0
                                border.color: theme.isGtk && menuItem.highlighted ? theme.accent : "transparent"
                            }
                        }
                        
                        MenuItem {
                            text: qsTr("Play now")
                            onTriggered: root.playClicked()
                        }
                        MenuItem {
                            text: qsTr("Add to queue")
                            onTriggered: root.queueClicked()
                        }
                        MenuSeparator {
                            contentItem: Rectangle {
                                implicitHeight: theme.borderWidthThin
                                color: theme.divider
                            }
                        }
                        MenuItem {
                            text: root.starred ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
                            enabled: root.trackId.length > 0
                            onTriggered: {
                                if (root.trackId.length > 0) {
                                    if (root.starred) {
                                        api.unstar(root.trackId)
                                    } else {
                                        api.star(root.trackId)
                                    }
                                    root.starred = !root.starred
                                }
                            }
                        }
                    }
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            acceptedDevices: PointerDevice.Mouse
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            gesturePolicy: TapHandler.DragThreshold
            onTapped: (eventPoint, button) => {
                if (button === Qt.LeftButton) {
                    root.playClicked()
                } else if (button === Qt.RightButton) {
                    trackMenu.popup()
                }
            }
        }
    }

    readonly property bool cardHovered: hoverHandler.hovered
}
