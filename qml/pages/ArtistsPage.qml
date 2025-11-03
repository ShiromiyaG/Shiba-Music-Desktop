import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    Components.ThemePalette { id: theme }
    id: artistsPage
    signal artistClicked(string artistId, string artistName, string coverArtId)

    background: Rectangle { color: "transparent" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.paddingPage
        spacing: theme.spacing2xl

        Label {
            text: qsTr("Artists")
            font.pixelSize: theme.fontSizeDisplay
            font.weight: Font.DemiBold
            color: theme.textPrimary
            Layout.leftMargin: 0
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: theme.spacingXl
            clip: true
            cellWidth: 196
            cellHeight: 244
            flickDeceleration: 1200
            maximumFlickVelocity: 2500
            model: (api && api.artists) ? api.artists : []
            delegate: Components.ArtistCard {
                name: modelData.name || qsTr("Artista desconhecido")
                cover: (modelData.coverArt && api) ? api.coverArtUrl(modelData.coverArt, 256) : ""
                onClicked: artistsPage.artistClicked(modelData.id, modelData.name, modelData.coverArt)
            }
            
            ScrollBar.vertical: Components.ScrollBar {
                theme.manager: themeManager
                policy: ScrollBar.AsNeeded
                visible: gridView.contentHeight > gridView.height
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












