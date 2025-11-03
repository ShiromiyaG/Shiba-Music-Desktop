import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Components

Item {
    Components.ThemePalette { id: theme }
    id: root
    width: parent ? parent.width : implicitWidth
    height: Math.max(titleLabel.implicitHeight, actionRow.implicitHeight)

    property string title
    property string subtitle: ""
    default property alias content: actionRow.data

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label {
                id: titleLabel
                text: root.title
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: theme.textPrimary
            }
            Label {
                text: root.subtitle
                visible: text.length > 0
                color: theme.textSecondary
                font.pixelSize: 12
            }
        }

        RowLayout {
            id: actionRow
            spacing: 8
        }
    }
}