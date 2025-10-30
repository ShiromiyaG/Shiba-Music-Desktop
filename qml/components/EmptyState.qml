import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 320
    height: Math.max(implicitHeight, 160)

    property string emoji: "🎧"
    property string title: "Nada por aqui ainda"
    property string description: ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8
        Loader {
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: emoji.startsWith("qrc:") ? imageComponent : textComponent
        }
        Label {
            text: root.title
            font.pixelSize: 16
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: root.description
            visible: text.length > 0
            color: "#8b96a8"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: Math.min(root.width, 420)
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Component {
        id: imageComponent
        Image {
            source: emoji
            sourceSize.width: 52
            sourceSize.height: 52
            antialiasing: true
        }
    }

    Component {
        id: textComponent
        Label {
            text: emoji
            font.pixelSize: 52
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
