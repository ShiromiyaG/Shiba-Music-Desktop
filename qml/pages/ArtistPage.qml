import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: artistPage
    padding: 16

    contentItem: Flickable {
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight

        Column {
            id: column
            width: parent.width
            spacing: 8

            Label {
                text: "Álbuns"
                font.pixelSize: 18
            }
            GridView {
                anchors.left: parent.left
                anchors.right: parent.right
                cellWidth: 180
                cellHeight: 240
                height: 480
                model: api.albums
                delegate: Components.AlbumCard {
                    title: modelData.name
                    subtitle: modelData.year > 0 ? modelData.year : ""
                    cover: api.coverArtUrl(modelData.coverArt, 300)
                    onClicked: {
                        api.fetchAlbum(modelData.id)
                        StackView.view.push("qrc:/qml/pages/AlbumPage.qml")
                    }
                }
            }
        }
    }
}
