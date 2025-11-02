import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: artistsPage
    signal artistClicked(string artistId, string artistName, string coverArtId)

    background: Rectangle { color: "transparent" }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 18

        Label {
            text: qsTr("Artists")
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: "#f5f7ff"
            Layout.leftMargin: 32
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 196
            cellHeight: 244
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            model: (api && api.artists) ? api.artists : []
            delegate: Components.ArtistCard {
                name: modelData.name || "Artista Desconhecido"
                cover: (modelData.coverArt && api) ? api.coverArtUrl(modelData.coverArt, 256) : ""
                onClicked: artistsPage.artistClicked(modelData.id, modelData.name, modelData.coverArt)
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y
                    gridView.contentY = Math.max(0, Math.min(gridView.contentY - delta, gridView.contentHeight - gridView.height))
                }
            }
        }
    }
}
