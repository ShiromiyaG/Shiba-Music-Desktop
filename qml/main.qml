import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1200; height: 800; visible: true
    title: "Shiba Music"
    Material.theme: Material.Dark
    Material.accent: Material.Indigo

    header: ToolBar {
        contentHeight: 48
        background: Rectangle { color: "#191C24"; opacity: 0.95 }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            Label { text: "Shiba Music"; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter }
            Item { Layout.fillWidth: true }
            TextField {
                id: searchBox; placeholderText: "Buscar"
                onAccepted: api.search(text)
                Layout.preferredWidth: 360
            }
        }
    }

    StackView {
        id: stack
        anchors.fill: parent

        Component.onCompleted: {
            push(api.authenticated ? "qrc:/qml/pages/HomePage.qml" : "qrc:/qml/pages/LoginPage.qml");
        }

        Connections {
            target: api
            function onAuthenticatedChanged() {
                stack.clear();
                stack.push(api.authenticated ? "qrc:/qml/pages/HomePage.qml" : "qrc:/qml/pages/LoginPage.qml");
            }
        }
    }

    footer: Loader { source: "qrc:/qml/components/NowPlayingBar.qml" }
}
