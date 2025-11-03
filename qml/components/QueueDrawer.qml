import QtQuick
import QtQuick.Controls
import "." as Local
import "." as Components
import QtQuick.Layouts

Drawer {
    id: root
    edge: Qt.RightEdge
    width: Math.min(parent ? parent.width * 0.32 : 360, 420)
    implicitHeight: parent ? parent.height : 600
    modal: false

    Components.ThemePalette { id: theme }

    background: Rectangle {
        color: theme.surface
        border.color: theme.surfaceBorder
    }

    property alias listView: queueList
    property var queueModel: []
    property string currentTrackId: ""
    signal requestPlay(int index)
    signal requestRemove(int index)
    signal requestClear()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Label {
                text: qsTr("Playback Queue")
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                color: theme.textPrimary
            }
            ToolButton {
                text: "✕"
                font.pixelSize: 14
                onClicked: root.close()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: queueList
                spacing: 8
                clip: true
                model: root.queueModel
                delegate: Item {
                    width: queueList.width
                    height: 72
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: modelData.id === root.currentTrackId ? theme.listItemActive : (hoverHandler.hovered ? theme.listItemHover : theme.cardBackground)
                        border.color: modelData.id === root.currentTrackId ? theme.accent : theme.cardBorder
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Album Cover
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 8
                            color: theme.surface
                            clip: true
                            
                            Image {
                                anchors.fill: parent
                                source: api.coverArtUrl(modelData.coverArt, 128)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        // Track Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            
                            Label {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: theme.textPrimary
                                elide: Label.ElideRight
                            }
                            
                            Label {
                                Layout.fillWidth: true
                                text: modelData.artist
                                font.pixelSize: 12
                                color: theme.textSecondary
                                elide: Label.ElideRight
                            }
                        }

                        // Action Buttons
                        Row {
                            spacing: 6
                            
                            ToolButton {
                                text: "▶"
                                onClicked: root.requestPlay(index)
                            }
                            
                            ToolButton {
                                text: "✕"
                                onClicked: root.requestRemove(index)
                            }
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                        acceptedDevices: PointerDevice.Mouse
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        gesturePolicy: TapHandler.DragThreshold
                        onTapped: root.requestPlay(index)
                    }
                }
                ScrollBar.vertical: Components.ScrollBar { theme.manager: themeManager }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: queueList.count === 0
            
            Local.EmptyState {
                anchors.centerIn: parent
                width: parent.width
                emoji: "📜"
                title: qsTr("Your queue is empty")
                description: "Adicione músicas tocando no botão + nas faixas."
            }
        }

        Button {
            Layout.fillWidth: true
            text: qsTr("Clear Queue")
            enabled: queueList.count > 0
            onClicked: root.requestClear()
            
            background: Rectangle {
                color: parent.enabled ? (parent.hovered ? theme.surfaceInteractive : theme.cardBackground) : theme.cardBackground
                radius: 8
                border.color: theme.surfaceInteractiveBorder
            }
        }
    }
}
