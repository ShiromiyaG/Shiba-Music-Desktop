import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "components" as Components

ApplicationWindow {
    id: win
    width: 1280
    height: 820
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "Shiba Music"
    Material.theme: Material.Dark
    Material.accent: Material.Indigo
    readonly property url homePageUrl: Qt.resolvedUrl("qrc:/qml/pages/HomePage.qml")
    readonly property url loginPageUrl: Qt.resolvedUrl("qrc:/qml/pages/LoginPage.qml")

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#151821" }
            GradientStop { position: 1.0; color: "#0f1117" }
        }
    }

    header: ToolBar {
        id: topBar
        contentHeight: 56
        background: Rectangle {
            color: "#181C25"
            border.color: "#252B36"
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            ToolButton {
                text: "←"
                enabled: stack.depth > 1
                onClicked: if (stack.depth > 1) stack.pop()
                ToolTip.visible: hovered
                ToolTip.text: "Voltar"
            }

            Label {
                text: "Shiba Music"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            TextField {
                id: searchBox
                placeholderText: "Buscar artistas, álbuns ou faixas"
                Layout.preferredWidth: 360
                leftPadding: 32
                rightPadding: clearButton.visible ? clearButton.width + 16 : 12
                onAccepted: {
                    if (text.length > 0) {
                        api.search(text)
                        if (stack.depth === 0) {
                            stack.push(win.homePageUrl)
                        } else if (stack.currentItem && stack.currentItem.objectName !== "homePage") {
                            stack.replace(win.homePageUrl)
                        }
                    }
                }

                background: Rectangle {
                    radius: 12
                    color: "#1f2532"
                    border.color: "#2b3240"
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: "🔍"
                    color: "#8b96a8"
                    font.pixelSize: 14
                }

                ToolButton {
                    id: clearButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    visible: searchBox.text.length > 0
                    onClicked: {
                        searchBox.clear()
                        api.search("")
                    }
                }
            }

            ToolButton {
                text: "🎵"
                onClicked: queueDrawer.open()
                ToolTip.visible: hovered
                ToolTip.text: "Fila"
            }
        }
    }

    footer: Components.NowPlayingBar {
        id: nowPlayingBar
        onQueueRequested: queueDrawer.open()
    }

    StackView {
        id: stack
        parent: win.contentItem
        anchors.fill: parent
        focus: true
        clip: true
        pushEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { property: "x"; from: stack.width * 0.08; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }
        pushExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
            NumberAnimation { property: "x"; from: 0; to: -stack.width * 0.06; duration: 180; easing.type: Easing.InCubic }
        }
        popEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "x"; from: -stack.width * 0.06; to: 0; duration: 180; easing.type: Easing.OutCubic }
        }
        popExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160 }
            NumberAnimation { property: "x"; from: 0; to: stack.width * 0.08; duration: 160; easing.type: Easing.InCubic }
        }

        Component.onCompleted: {
            push(api.authenticated ? win.homePageUrl : win.loginPageUrl);
        }
    }

    Connections {
        target: api
        function onAuthenticatedChanged() {
            stack.clear()
            stack.push(api.authenticated ? win.homePageUrl : win.loginPageUrl)
        }
    }

    Components.QueueDrawer {
        id: queueDrawer
        parent: win.contentItem
        queueModel: player.queue
        currentTrackId: (player.currentTrack && player.currentTrack.id) ? player.currentTrack.id : ""
        onRequestPlay: player.playFromQueue(index)
        onRequestRemove: player.removeFromQueue(index)
        onRequestClear: player.clearQueue()
    }

    Shortcut {
        sequences: [StandardKey.Find, StandardKey.Search]
        onActivated: searchBox.forceActiveFocus()
    }
}
