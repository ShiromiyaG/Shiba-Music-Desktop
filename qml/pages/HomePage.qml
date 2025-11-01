import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: homePage
    objectName: "homePage"
    signal albumClicked(string albumId, string albumTitle, string artistName, string coverArtId, string artistId)
    signal artistClicked(string artistId, string artistName, string coverArtId)
    padding: 0
    background: Rectangle { color: "transparent" }

    property bool searchActive: false
    property bool searchLoading: false
    property string searchQuery: ""
    property var searchResults: []
    property var searchArtistsResults: []
    property var searchAlbumsResults: []

    onSearchActiveChanged: if (!searchActive) {
        searchLoading = false
        searchResults = []
        searchArtistsResults = []
        searchAlbumsResults = []
        searchQuery = ""
    }

    Connections {
        target: api
        function onSearchArtistsChanged() {
            if (!homePage.searchActive) return
            var results = api.searchArtists || []
            var copy = []
            if (results && results.length) {
                for (var i = 0; i < results.length; ++i)
                    copy.push(results[i])
            }
            homePage.searchArtistsResults = copy
        }
        function onSearchAlbumsChanged() {
            if (!homePage.searchActive) return
            var results = api.searchAlbums || []
            var copy = []
            if (results && results.length) {
                for (var i = 0; i < results.length; ++i)
                    copy.push(results[i])
            }
            homePage.searchAlbumsResults = copy
        }
        function onTracksChanged() {
            if (!homePage.searchActive)
                return
            var results = api.tracks || []
            var copy = []
            if (results && results.length) {
                for (var i = 0; i < results.length; ++i)
                    copy.push(results[i])
            }
            homePage.searchResults = copy
            homePage.searchLoading = false
        }
        function onErrorOccurred(message) {
            if (!homePage.searchActive)
                return
            if (homePage.searchLoading) {
                homePage.searchLoading = false
                homePage.searchResults = []
                homePage.searchArtistsResults = []
                homePage.searchAlbumsResults = []
            }
        }
    }

    Component.onCompleted: {
        api.fetchRandomSongs();
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: column.width
        contentHeight: column.height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: column
            width: scrollArea.width
            spacing: 24
            padding: 32

            // Search results - shown exclusively when search is active
            Item {
                width: column.width
                visible: searchActive
                implicitHeight: searchSectionContent.implicitHeight
                Column {
                    id: searchSectionContent
                    width: parent.width - column.padding * 2
                    x: column.padding
                    spacing: 0
                    
                    Label {
                        text: searchQuery.length ? ("Resultados para \"" + searchQuery + "\"") : "Resultados da busca"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        color: "#f5f7ff"
                    }
                    
                    Loader {
                        width: parent.width
                        sourceComponent: searchLoading ? searchResultsLoading : null
                    }
                    
                    // Artists section
                    Column {
                        width: parent.width
                        spacing: 4
                        topPadding: 4
                        visible: !searchLoading && searchArtistsResults.length > 0
                        
                        Label {
                            text: "ARTISTAS"
                            color: "#8da0c0"
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.DemiBold
                        }
                        
                        Item {
                            width: parent.width
                            height: 230
                            
                            Flickable {
                                id: artistsScroll
                                anchors.fill: parent
                                clip: true
                                contentWidth: artistsRow.width
                                contentHeight: artistsRow.height
                                boundsBehavior: Flickable.StopAtBounds
                                flickableDirection: Flickable.HorizontalFlick
                                
                                Row {
                                    id: artistsRow
                                    spacing: 16
                                    Repeater {
                                        model: searchArtistsResults
                                        delegate: Components.ArtistCard {
                                            name: modelData.name || "Artista Desconhecido"
                                            albumCount: modelData.albumCount || 0
                                            cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                            artistId: modelData.id
                                            onClicked: homePage.artistClicked(modelData.id, modelData.name, modelData.coverArt)
                                        }
                                    }
                                }
                            }
                        }
                        
                        ScrollBar {
                            width: parent.width
                            orientation: Qt.Horizontal
                            size: artistsScroll.width / artistsScroll.contentWidth
                            position: artistsScroll.contentX / artistsScroll.contentWidth
                            active: true
                            onPositionChanged: {
                                if (pressed) {
                                    artistsScroll.contentX = position * artistsScroll.contentWidth
                                }
                            }
                        }
                    }
                    
                    // Albums section
                    Column {
                        width: parent.width
                        spacing: 8
                        topPadding: 28
                        visible: !searchLoading && searchAlbumsResults.length > 0
                        
                        Label {
                            text: "ÁLBUNS"
                            color: "#8da0c0"
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.DemiBold
                        }
                        
                        Item {
                            width: parent.width
                            height: 270
                            
                            Flickable {
                                id: albumsScroll
                                anchors.fill: parent
                                clip: true
                                contentWidth: albumsRow.width
                                contentHeight: albumsRow.height
                                boundsBehavior: Flickable.StopAtBounds
                                flickableDirection: Flickable.HorizontalFlick
                                
                                Row {
                                    id: albumsRow
                                    spacing: 16
                                    Repeater {
                                        model: searchAlbumsResults
                                        delegate: Components.AlbumCard {
                                            title: modelData.name || "Álbum Desconhecido"
                                            subtitle: modelData.artist || "Artista desconhecido"
                                            cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                            albumId: modelData.id
                                            artistId: modelData.artistId || ""
                                            onClicked: homePage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
                                        }
                                    }
                                }
                            }
                        }
                        
                        ScrollBar {
                            width: parent.width
                            orientation: Qt.Horizontal
                            size: albumsScroll.width / albumsScroll.contentWidth
                            position: albumsScroll.contentX / albumsScroll.contentWidth
                            active: true
                            onPositionChanged: {
                                if (pressed) {
                                    albumsScroll.contentX = position * albumsScroll.contentWidth
                                }
                            }
                        }
                    }
                    
                    // Songs section
                    Column {
                        width: parent.width
                        spacing: 8
                        topPadding: 28
                        visible: !searchLoading && searchResults.length > 0
                        
                        Label {
                            text: "MÚSICAS"
                            color: "#8da0c0"
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.DemiBold
                        }
                        
                        Loader {
                            width: parent.width
                            sourceComponent: searchResultsList
                        }
                    }
                    
                    // Empty state
                    Loader {
                        width: parent.width
                        visible: !searchLoading && searchArtistsResults.length === 0 && searchAlbumsResults.length === 0 && searchResults.length === 0
                        sourceComponent: searchResultsEmpty
                    }
                }
            }

            // Normal content - hidden when search is active
            Label {
                visible: !searchActive
                text: "Discover"
                font.pixelSize: 30
                font.weight: Font.DemiBold
                color: "#f5f7ff"
            }

            Label {
                visible: !searchActive
                text: "RECENTLY PLAYED"
                color: "#8da0c0"
                font.pixelSize: 12
                font.letterSpacing: 4
                font.weight: Font.DemiBold
            }

            Loader {
                visible: !searchActive
                width: column.width - column.padding * 2
                sourceComponent: api.recentlyPlayedAlbums.length > 0 ? recentlyPlayed : emptyState
            }

            Label {
                visible: !searchActive
                text: "MADE FOR YOU"
                color: "#8da0c0"
                font.pixelSize: 12
                font.letterSpacing: 4
                font.weight: Font.DemiBold
            }

            Loader {
                visible: !searchActive
                width: column.width - column.padding * 2
                sourceComponent: api.randomSongs.length > 0 ? madeForYou : emptyState
            }
        }
    }

    Component {
        id: recentlyPlayed
        Column {
            width: parent.width
            spacing: 8
            
            Item {
                id: recentWrapper
                width: parent.width
                height: 270
                clip: false

                Flickable {
                    id: recentScroll
                    anchors.fill: parent
                    clip: true
                    contentWidth: recentRow.width
                    contentHeight: recentRow.height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: false

                    Row {
                        id: recentRow
                        spacing: 16
                        Repeater {
                            model: api.recentlyPlayedAlbums
                            delegate: Components.AlbumCard {
                                title: modelData.name || "Álbum Desconhecido"
                                subtitle: modelData.artist || "Artista desconhecido"
                                cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                albumId: modelData.id
                                artistId: modelData.artistId || ""
                                onClicked: homePage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
                            }
                        }
                    }
                }
            }
            
            ScrollBar {
                id: recentScrollBar
                width: parent.width
                orientation: Qt.Horizontal
                size: recentScroll.width / recentScroll.contentWidth
                position: recentScroll.contentX / recentScroll.contentWidth
                active: true
                onPositionChanged: {
                    if (pressed) {
                        recentScroll.contentX = position * recentScroll.contentWidth
                    }
                }
            }
        }
    }

    Component {
        id: searchResultsLoading
        Item {
            width: parent ? parent.width : 0
            height: 80
            BusyIndicator {
                anchors.centerIn: parent
                running: true
            }
        }
    }

    Component {
        id: searchResultsList
        Item {
            width: parent ? parent.width : 0
            implicitHeight: resultsColumn.implicitHeight

            Column {
                id: resultsColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: homePage.searchResults
                    delegate: Rectangle {
                        property var track: modelData
                        width: resultsColumn.width
                        height: 72
                        radius: 16
                        color: trackHover.hovered ? "#273040" : (index % 2 === 0 ? "#1b2336" : "#182030")
                        border.color: trackHover.hovered ? "#3b465f" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler {
                            id: trackHover
                        }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                Layout.alignment: Qt.AlignVCenter
                                radius: 8
                                color: "#101622"
                                clip: true
                                
                                Image {
                                    anchors.fill: parent
                                    source: track.coverArt ? api.coverArtUrl(track.coverArt, 128) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: track.coverArt && status !== Image.Error
                                }
                                
                                Image {
                                    anchors.centerIn: parent
                                    visible: !track.coverArt || parent.children[0].status === Image.Error
                                    source: "qrc:/qml/icons/music_note.svg"
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    antialiasing: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 180
                                spacing: 2
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: track.title || "-"
                                    color: "#f5f7ff"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: track.artist || "-"
                                    color: "#8fa0c2"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                            
                            Label {
                                text: track.album || "-"
                                color: "#8fa0c2"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.preferredWidth: 180
                                Layout.maximumWidth: 220
                            }
                            
                            RowLayout {
                                spacing: 4
                                
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/add.svg"
                                    display: AbstractButton.IconOnly
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Adicionar à fila"
                                    onClicked: player.addToQueue(track)
                                }
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                                    display: AbstractButton.IconOnly
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Reproduzir agora"
                                    onClicked: player.playAlbum([track], 0)
                                }
                            }
                        }
                        
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: player.playAlbum([track], 0)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: searchResultsEmpty
        Components.EmptyState {
            width: parent ? parent.width : 0
            emoji: "qrc:/qml/icons/search.svg"
            title: "Nada encontrado"
            description: "Tente outro termo ou verifique a grafia."
        }
    }

    Component {
        id: madeForYou
        Column {
            width: parent.width
            spacing: 10
            ListView {
                id: madeList
                height: contentHeight
                width: parent.width
                clip: true
                spacing: 8
                interactive: false
                model: api.randomSongs
                delegate: Rectangle {
                    property var track: modelData
                    width: madeList.width
                    height: 60
                    radius: 16
                    color: madeTrackHover.hovered ? "#273040" : (index % 2 === 0 ? "#1b2336" : "#182030")
                    border.color: madeTrackHover.hovered ? "#3b465f" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    HoverHandler {
                        id: madeTrackHover
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 18

                        Label {
                            text: "#" + (index + 1)
                            color: "#8da0c0"
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 28
                            horizontalAlignment: Text.AlignLeft
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: "#101622"
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: track.coverArt ? api.coverArtUrl(track.coverArt, 128) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: track.coverArt && status !== Image.Error
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: !track.coverArt
                                text: "♪"
                                color: "#55617b"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 200
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: track.title || "Faixa desconhecida"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: track.artist || "-"
                                color: "#8fa0c2"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Label {
                            text: track.album || "-"
                            color: "#8fa0c2"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8
                            ToolButton {
                                property bool isFavorite: track.starred || false
                                display: AbstractButton.IconOnly
                                icon.source: isFavorite ? "qrc:/qml/icons/favorite.svg" : "qrc:/qml/icons/favorite_border.svg"
                                icon.color: isFavorite ? "#ff6b6b" : "#8da0c0"
                                icon.width: 20
                                icon.height: 20
                                onClicked: {
                                    if (isFavorite) {
                                        api.unstar(track.id)
                                    } else {
                                        api.star(track.id)
                                    }
                                    isFavorite = !isFavorite
                                }
                            }
                            ToolButton {
                                text: "⋯"
                                onClicked: trackMenu.popup()
                                
                                Menu {
                                    id: trackMenu
                                    width: 200
                                    
                                    background: Rectangle {
                                        color: "#1d2330"
                                        radius: 12
                                        border.color: "#2a3040"
                                        border.width: 1
                                    }
                                    
                                    delegate: MenuItem {
                                        id: menuItem
                                        implicitWidth: 200
                                        implicitHeight: 40
                                        
                                        contentItem: Label {
                                            text: menuItem.text
                                            color: menuItem.highlighted ? "#f5f7ff" : "#b0b8c8"
                                            font.pixelSize: 13
                                            leftPadding: 16
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        background: Rectangle {
                                            color: menuItem.highlighted ? "#2a3545" : "transparent"
                                            radius: 8
                                        }
                                    }
                                    
                                    MenuItem {
                                        text: "Tocar agora"
                                        onTriggered: player.playAlbum([track], 0)
                                    }
                                    MenuItem {
                                        text: "Adicionar à fila"
                                        onTriggered: player.addToQueue(track)
                                    }
                                    MenuItem {
                                        text: "Ir para álbum"
                                        onTriggered: homePage.albumClicked(track.albumId, track.album, track.artist, track.coverArt, track.artistId || "")
                                    }
                                }
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: player.playAlbum([track], 0)
                    }
                }
            }
        }
    }

    Component {
        id: emptyState
        Components.EmptyState {
            width: parent.width
            emoji: "🎧"
            title: "Nada por aqui ainda"
            description: "Busque ou atualize sua biblioteca para preencher estas seções."
        }
    }
}
