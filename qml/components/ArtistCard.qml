import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "." as Components

Item {
    Components.ThemePalette { id: theme }
    id: root
    width: 176
    height: 224
    property string name
    property url cover
    property int albumCount: 0
    property string artistId: ""
    signal clicked()

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: theme.isGtk ? theme.radiusChip : theme.radiusCard
        color: hoverArea.containsMouse ? (theme.isMica ? Qt.tint(theme.listItemHover, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)) : theme.listItemHover)
                                     : (theme.isMica ? Qt.rgba(theme.cardBackground.r, theme.cardBackground.g, theme.cardBackground.b, 0.94) : theme.cardBackground)
        border.color: hoverArea.containsMouse ? theme.surfaceInteractiveBorder : theme.cardBorder
        border.width: theme.isGtk ? theme.borderWidthThin : (theme.isMica ? theme.borderWidthThin : 0)
        Behavior on color { ColorAnimation { duration: 120 } }

                ColumnLayout {
            anchors.fill: parent
            anchors.margins: theme.isGtk ? theme.spacingMd : theme.spacingLg
            spacing: theme.isGtk ? theme.spacingSm : theme.spacingMd + theme.spacingXs / 2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: theme.isGtk ? theme.radiusBadge : theme.radiusButton
                    color: theme.surface
                    border.color: theme.cardBorder
                    border.width: theme.isGtk ? theme.borderWidthThin : 0
                    clip: true
                    Image {
                        id: coverImage
                        anchors.fill: parent
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
                    color: theme.surface
                    visible: coverImage.status !== Image.Ready
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qml/icons/mic.svg"
                        sourceSize.width: theme.iconSizeLarge * 1.75
                        sourceSize.height: theme.iconSizeLarge * 1.75
                        antialiasing: true
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: theme.spacingXs / 2
                
                Label {
                    width: parent.width
                    text: root.name
                    font.pixelSize: theme.isGtk ? theme.fontSizeSubtitle : theme.fontSizeBody
                    font.weight: Font.Medium
                    color: theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    clip: true
                }
                
                Label {
                    width: parent.width
                    text: root.albumCount > 0 ? (root.albumCount + " álbun" + (root.albumCount !== 1 ? "s" : "")) : ""
                    font.pixelSize: theme.isGtk ? theme.fontSizeCaption : theme.fontSizeExtraSmall
                    color: theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.albumCount > 0
                }
            }

            Item {
                Layout.fillHeight: true
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
                    text: qsTr("View Artist")
                    onTriggered: root.clicked()
                }
            }
        }
    }
}
