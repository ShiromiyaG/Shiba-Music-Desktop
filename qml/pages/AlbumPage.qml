import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: albumPage
    padding: 16

    contentItem: ListView {
        clip: true
        spacing: 8
        model: api.tracks
        delegate: Components.TrackRow {
            title: (modelData.track > 0 ? (modelData.track + ". ") : "") + modelData.title
            subtitle: modelData.artist
            duration: modelData.duration
            cover: api.coverArtUrl(modelData.coverArt, 128)
            onPlayClicked: player.playTrack(modelData)
            onQueueClicked: player.addToQueue(modelData)
        }
    }
}
