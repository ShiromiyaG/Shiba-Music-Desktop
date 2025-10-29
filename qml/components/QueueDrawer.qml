import QtQuick
import QtQuick.Controls
import "." as Local
import QtQuick.Layouts

Drawer {
    id: root
    edge: Qt.RightEdge
    width: Math.min(parent ? parent.width * 0.32 : 360, 420)
    implicitHeight: parent ? parent.height : 600
    modal: false

    background: Rectangle {
        color: "#191C24"
        border.color: "#222833"
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
                text: "Fila de Reprodução"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
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
            contentItem: ListView {
                id: queueList
                spacing: 8
                clip: true
                model: root.queueModel
                delegate: Rectangle {
                    width: queueList.width
                    height: 72
                    radius: 10
                    color: modelData.id === root.currentTrackId ? "#273140" : "#1B2028"
                    border.color: modelData.id === root.currentTrackId ? "#3D4A5F" : "#252C36"
                    Behavior on color { ColorAnimation { duration: 160 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            width: 52; height: 52; radius: 8; color: "#111"; clip: true
                            Image {
                                anchors.fill: parent
                                source: api.coverArtUrl(modelData.coverArt, 128)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: modelData.title
                                font.pixelSize: 14
                                elide: Label.ElideRight
                            }
                            Label {
                                text: modelData.artist
                                color: "#8b96a8"
                                font.pixelSize: 12
                                elide: Label.ElideRight
                            }
                        }

                        ToolButton {
                            text: "▶"
                            onClicked: root.requestPlay(index)
                        }
                        ToolButton {
                            text: "✕"
                            onClicked: root.requestRemove(index)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.requestPlay(index)
                        onEntered: parent.color = "#242B38"
                        onExited: parent.color = modelData.id === root.currentTrackId ? "#273140" : "#1B2028"
                    }
                }
                ScrollBar.vertical: ScrollBar { }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: queueList.count === 0
            sourceComponent: emptyQueue
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ToolButton {
                text: "Limpar fila"
                enabled: queueList.count > 0
                onClicked: root.requestClear()
            }
            Item { Layout.fillWidth: true }
        }
    }

    Component {
        id: emptyQueue
        Local.EmptyState {
            width: root.width - 32
            emoji: "📜"
            title: "Sua fila está vazia"
            description: "Adicione músicas tocando no botão + nas faixas."
        }
    }
}
