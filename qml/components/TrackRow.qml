import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/js/utils.js" as Utils

Item {
    id: root
    width: parent ? parent.width : 640
    height: 72

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
        radius: 12
        color: cardHovered ? "#242c3a" : "#1b2029"
        border.color: cardHovered ? "#3b465a" : "#252c36"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Label {
                text: root.index >= 0 ? root.index + 1 : ""
                visible: root.index >= 0
                Layout.preferredWidth: visible ? 28 : 0
                color: "#5f6a7c"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
            }

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 8
                color: "#111"
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
                    sourceSize.width: 20
                    sourceSize.height: 20
                    antialiasing: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Label.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: root.subtitle
                    elide: Label.ElideRight
                    color: "#8b96a8"
                    font.pixelSize: 12
                }
            }

            Label {
                text: Utils.durationToText(root.duration || 0)
                color: "#8b96a8"
                font.pixelSize: 12
            }

            Row {
                spacing: 6
                ToolButton {
                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                    onClicked: root.playClicked()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Play now")
                }
                ToolButton {
                    text: "⋯"
                    onClicked: trackMenu.popup()
                    
                    Menu {
                        id: trackMenu
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
                            text: qsTr("Play now")
                            onTriggered: root.playClicked()
                        }
                        MenuItem {
                            text: qsTr("Add to queue")
                            onTriggered: root.queueClicked()
                        }
                        MenuSeparator {
                            contentItem: Rectangle {
                                implicitHeight: 1
                                color: "#2a3040"
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
