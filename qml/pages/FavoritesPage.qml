import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    Components.ThemePalette { id: theme }
    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchFavorites();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 18

        Label {
            text: qsTr("Favorites")
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: theme.textPrimary
            Layout.leftMargin: 32
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            model: api.favorites
            delegate: Components.TrackRow {
                width: listView.width
                title: modelData.title
                subtitle: modelData.artist
                duration: modelData.duration
                cover: api.coverArtUrl(modelData.coverArt, 128)
                onPlayClicked: player.playTrack(modelData)
                onQueueClicked: player.addToQueue(modelData)
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y
                    listView.contentY = Math.max(0, Math.min(listView.contentY - delta, listView.contentHeight - listView.height))
                }
            }
        }
    }
}
