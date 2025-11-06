import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    id: homePage
    Components.ThemePalette { id: theme }
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
        api.fetchRecentlyPlayedAlbums();
        api.fetchMostPlayedAlbums();
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: column.width
        contentHeight: column.height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        flickDeceleration: 1200
        maximumFlickVelocity: 2500
        ScrollBar.vertical: Components.ScrollBar {
            theme.manager: themeManager
        }
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                var delta = wheel.angleDelta.y
                scrollArea.contentY = Math.max(0, Math.min(scrollArea.contentY - delta, scrollArea.contentHeight - scrollArea.height))
            }
        }

        Column {
            id: column
            width: scrollArea.width
            spacing: theme.spacing3xl
            padding: theme.paddingPage

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
                        text: searchQuery.length
                        ? qsTr("Resultados para \"%1\"").arg(searchQuery)
                        : qsTr("Resultados da busca")
                        font.pixelSize: theme.fontSizeDisplay
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }
                    
                    Loader {
                        width: parent.width
                        sourceComponent: searchLoading ? searchResultsLoading : null
                    }
                    
                    // Artists section
                    Column {
                        width: parent.width
                        spacing: theme.spacingXs
                        topPadding: 4
                        visible: !searchLoading && searchArtistsResults.length > 0
                        
                        Label {
                            text: qsTr("Artists")
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeExtraSmall
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
                                    spacing: theme.spacingXl
                                    Repeater {
                                        model: searchArtistsResults
                                        delegate: Components.ArtistCard {
                                            name: modelData.name || qsTr("Artista Desconhecido")
                                            albumCount: modelData.albumCount || 0
                                            cover: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                            artistId: modelData.id
                                            onClicked: homePage.artistClicked(modelData.id, modelData.name, modelData.coverArt)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Components.ScrollBar {
                            theme.manager: themeManager
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
                        spacing: theme.spacingMd
                        topPadding: 28
                        visible: !searchLoading && searchAlbumsResults.length > 0
                        
                        Label {
                            text: qsTr("Albums")
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeExtraSmall
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
                                    spacing: theme.spacingXl
                                    Repeater {
                                        model: searchAlbumsResults
                                        delegate: Components.AlbumCard {
                                            title: modelData.name || qsTr("Álbum Desconhecido")
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
                        
                        Components.ScrollBar {
                            theme.manager: themeManager
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
                        spacing: theme.spacingMd
                        topPadding: 28
                        visible: !searchLoading && searchResults.length > 0
                        
                        Label {
                            text: qsTr("SONGS")
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeExtraSmall
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
                text: qsTr("Discover")
                font.pixelSize: theme.fontSizeHeroTitle
                font.weight: Font.DemiBold
                color: theme.textPrimary
            }

            Label {
                visible: !searchActive
                text: qsTr("RECENTLY PLAYED")
                color: theme.textSecondary
                font.pixelSize: theme.fontSizeCaption
                font.letterSpacing: theme.spacingXs
                font.weight: Font.DemiBold
            }

            Loader {
                visible: !searchActive
                width: column.width - column.padding * 2
                sourceComponent: (api && api.recentlyPlayedAlbums && api.recentlyPlayedAlbums.length > 0) ? recentlyPlayed : emptyState
            }

            Label {
                visible: !searchActive
                text: qsTr("MADE FOR YOU")
                color: theme.textSecondary
                font.pixelSize: theme.fontSizeCaption
                font.letterSpacing: theme.spacingXs
                font.weight: Font.DemiBold
            }

            Loader {
                visible: !searchActive
                width: column.width - column.padding * 2
                sourceComponent: (api && api.randomSongs && api.randomSongs.length > 0) ? madeForYou : emptyState
            }

            Label {
                visible: !searchActive
                text: qsTr("MOST PLAYED")
                color: theme.textSecondary
                font.pixelSize: theme.fontSizeCaption
                font.letterSpacing: theme.spacingXs
                font.weight: Font.DemiBold
            }

            Loader {
                visible: !searchActive
                width: column.width - column.padding * 2
                sourceComponent: (api && api.mostPlayedAlbums && api.mostPlayedAlbums.length > 0) ? mostPlayed : emptyState
            }
        }
    }

    Component {
        id: recentlyPlayed
        Column {
            width: parent.width
            spacing: theme.spacingMd
            
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
                        spacing: theme.spacingXl
                        Repeater {
                            model: (api && api.recentlyPlayedAlbums) ? api.recentlyPlayedAlbums : []
                            delegate: Components.AlbumCard {
                                title: modelData.name || qsTr("Álbum Desconhecido")
                                subtitle: modelData.artist || "Artista desconhecido"
                                cover: (modelData.coverArt && api) ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                albumId: modelData.id
                                artistId: modelData.artistId || ""
                                onClicked: homePage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
                            }
                        }
                    }
                }
            }
            
            Components.ScrollBar {
                theme.manager: themeManager
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
        id: mostPlayed
        Column {
            width: parent.width
            spacing: theme.spacingMd

            Item {
                id: mostWrapper
                width: parent.width
                height: 270
                clip: false

                Flickable {
                    id: mostScroll
                    anchors.fill: parent
                    clip: true
                    contentWidth: mostRow.width
                    contentHeight: mostRow.height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: false

                    Row {
                        id: mostRow
                        spacing: theme.spacingXl
                        Repeater {
                            model: (api && api.mostPlayedAlbums) ? api.mostPlayedAlbums : []
                            delegate: Components.AlbumCard {
                                title: modelData.name || qsTr("Álbum Desconhecido")
                                subtitle: modelData.artist || qsTr("Artista desconhecido")
                                cover: (modelData.coverArt && api) ? api.coverArtUrl(modelData.coverArt, 256) : ""
                                albumId: modelData.id
                                artistId: modelData.artistId || ""
                                onClicked: homePage.albumClicked(modelData.id, modelData.name, modelData.artist, modelData.coverArt, modelData.artistId || "")
                            }
                        }
                    }
                }
            }

            Components.ScrollBar {
                theme.manager: themeManager
                width: parent.width
                orientation: Qt.Horizontal
                size: mostScroll.width / mostScroll.contentWidth
                position: mostScroll.contentX / mostScroll.contentWidth
                active: true
                onPositionChanged: {
                    if (pressed) {
                        mostScroll.contentX = position * mostScroll.contentWidth
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
                spacing: theme.spacingMd

                Repeater {
                    model: homePage.searchResults
                    delegate: Rectangle {
                        property var track: modelData
                        width: resultsColumn.width
                        height: 72
                        radius: theme.radiusCard
                        color: trackHover.hovered ? theme.listItemHover : (index % 2 === 0 ? theme.listItem : theme.listItemAlternate)
                        border.color: trackHover.hovered ? theme.surfaceInteractiveBorder : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler {
                            id: trackHover
                        }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: theme.spacingLg
                            anchors.rightMargin: theme.spacingLg
                            spacing: theme.spacingXl

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                Layout.alignment: Qt.AlignVCenter
                                radius: theme.radiusChip
                                color: theme.surface
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
                                spacing: theme.spacingXs
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: track.title || "-"
                                    color: theme.textPrimary
                                    font.pixelSize: theme.fontSizeBody
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: track.artist || "-"
                                    color: theme.textSecondary
                                    font.pixelSize: theme.fontSizeCaption
                                    elide: Text.ElideRight
                                }
                            }
                            
                            Label {
                                text: track.album || "-"
                                color: theme.textSecondary
                                font.pixelSize: theme.fontSizeCaption
                                elide: Text.ElideRight
                                Layout.preferredWidth: 180
                                Layout.maximumWidth: 220
                            }
                            
                            RowLayout {
                                spacing: theme.spacingXs
                                
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/add.svg"
                                    display: AbstractButton.IconOnly
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Add to queue")
                                    onClicked: player.addToQueue(track)
                                }
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                                    display: AbstractButton.IconOnly
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Play now")
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
            title: qsTr("Nothing found")
            description: qsTr("Tente outro termo ou verifique a grafia.")
        }
    }

    Component {
        id: madeForYou
        Column {
            width: parent.width
            spacing: theme.spacingLg
            ListView {
                id: madeList
                height: contentHeight
                width: parent.width
                clip: true
                spacing: theme.spacingMd
                interactive: false
                model: (api && api.randomSongs) ? api.randomSongs : []
                delegate: Rectangle {
                    property var track: modelData
                    width: madeList.width
                    height: 60
                    radius: theme.radiusCard
                    color: madeTrackHover.hovered ? theme.listItemHover : (index % 2 === 0 ? theme.listItem : theme.listItemAlternate)
                    border.color: madeTrackHover.hovered ? theme.surfaceInteractiveBorder : "transparent"
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
                        spacing: theme.spacing2xl

                        Label {
                            text: "#" + (index + 1)
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSizeSmall
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 28
                            horizontalAlignment: Text.AlignLeft
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            Layout.alignment: Qt.AlignVCenter
                            radius: theme.radiusButton
                            color: theme.surface
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: (track.coverArt && api) ? api.coverArtUrl(track.coverArt, 128) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: track.coverArt && status !== Image.Error
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: !track.coverArt
                                text: "♪"
                                color: theme.textMuted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 200
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            spacing: theme.spacingXs
                            Label {
                                Layout.fillWidth: true
                                text: track.title || qsTr("Faixa desconhecida")
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: track.artist || "-"
                                color: theme.textSecondary
                                font.pixelSize: theme.fontSizeCaption
                                elide: Text.ElideRight
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: albumLabel.implicitHeight
                            property bool hasAlbumNavigation: track && track.albumId && track.albumId.length > 0

                            Label {
                                id: albumLabel
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: track.album || "-"
                                color: albumArea.enabled && albumArea.containsMouse ? theme.textPrimary : theme.textSecondary
                                font.pixelSize: theme.fontSizeCaption
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: albumArea
                                x: 0
                                anchors.verticalCenter: albumLabel.verticalCenter
                                width: Math.min(albumLabel.contentWidth, albumLabel.width)
                                height: albumLabel.implicitHeight
                                hoverEnabled: true
                                enabled: parent.hasAlbumNavigation && width > 0
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: mouse.accepted = true
                                onClicked: homePage.albumClicked(track.albumId || "", track.album || "", track.artist || "", track.coverArt || "", track.artistId || "")
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: theme.spacingMd
                            ToolButton {
                                property bool isFavorite: track.starred || false
                                display: AbstractButton.IconOnly
                                icon.source: isFavorite ? "qrc:/qml/icons/favorite.svg" : "qrc:/qml/icons/favorite_border.svg"
                                icon.color: isFavorite ? "#ff6b6b" : theme.textSecondary
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
                                        color: theme.cardBackground
                                        radius: theme.radiusButton
                                        border.color: theme.cardBorder
                                        border.width: 1
                                    }
                                    
                                    delegate: MenuItem {
                                        id: menuItem
                                        implicitWidth: 200
                                        implicitHeight: 40
                                        
                                        contentItem: Label {
                                            text: menuItem.text
                                            color: menuItem.highlighted ? theme.textPrimary : theme.textSecondary
                                            font.pixelSize: theme.fontSizeSmall
                                            leftPadding: theme.paddingCard
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        background: Rectangle {
                                            color: menuItem.highlighted ? theme.listItemHover : "transparent"
                                            radius: theme.radiusChip
                                        }
                                    }
                                    
                                    MenuItem {
                                        text: qsTr("Play now")
                                        onTriggered: player.playAlbum([track], 0)
                                    }
                                    MenuItem {
                                        text: qsTr("Add to queue")
                                        onTriggered: player.addToQueue(track)
                                    }
                                    MenuItem {
                                        text: qsTr("Go to album")
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
            title: qsTr("Nothing here yet")
            description: qsTr("Busque ou atualize sua biblioteca para preencher estas seções.")
        }
    }
}














