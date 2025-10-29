import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
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
            }
            Label {
                text: root.subtitle
                visible: text.length > 0
                color: "#8b96a8"
                font.pixelSize: 12
            }
        }

        RowLayout {
            id: actionRow
            spacing: 8
        }
    }
}
