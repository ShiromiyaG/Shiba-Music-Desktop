import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Components

Item {
    Components.ThemePalette { id: theme }
    id: root
    width: parent ? parent.width : 320
    height: Math.max(implicitHeight, 160)

    property string emoji: "🎧"
    property string title: qsTr("Nothing here yet")
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
            color: theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: root.description
            visible: text.length > 0
            color: theme.textSecondary
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