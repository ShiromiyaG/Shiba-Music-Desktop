import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: albumsPage
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId)

    background: Rectangle { color: "transparent" }

    Component.onCompleted: {
        api.fetchAlbumList("random");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        Label {
            text: "Álbuns"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            color: "#f5f7ff"
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: api.albumList
            delegate: Rectangle {
                width: listView.width
                height: 60
                radius: 14
                color: index % 2 === 0 ? "#1b2336" : "#182030"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Label {
                        text: modelData.name || "Álbum Desconhecido"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        elide: Label.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: albumsPage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt)
                }
            }
        }
    }
}