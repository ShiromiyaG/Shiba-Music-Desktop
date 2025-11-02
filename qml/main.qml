import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window 2.15
import "components" as Components

ApplicationWindow {
    id: win
    width: 1360
    height: 840
    minimumWidth: 1080
    minimumHeight: 720
    color: "#11141a"
    title: qsTr("Shiba Music")
    Material.theme: Material.Dark
    Material.accent: Material.Indigo

    readonly property url homePageUrl: Qt.resolvedUrl("qrc:/qml/pages/HomePage.qml")
    readonly property url loginPageUrl: Qt.resolvedUrl("qrc:/qml/pages/LoginPage.qml")
    readonly property url artistsPageUrl: Qt.resolvedUrl("qrc:/qml/pages/ArtistsPage.qml")
    readonly property url albumsPageUrl: Qt.resolvedUrl("qrc:/qml/pages/AlbumsPage.qml")
    readonly property url favoritesPageUrl: Qt.resolvedUrl("qrc:/qml/pages/FavoritesPage.qml")

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#141926" }
            GradientStop { position: 1.0; color: "#0c0f18" }
        }
    }

    function getNavigationItems() {
        return [
            { label: qsTr("Home"), icon: "qrc:/qml/icons/home.svg", target: "home" },
            { label: qsTr("Playlists"), icon: "qrc:/qml/icons/queue_music.svg", target: "playlists" },
            { label: qsTr("Favorites"), icon: "qrc:/qml/icons/star.svg", target: "favorites" },
            { label: qsTr("Albums"), icon: "qrc:/qml/icons/album.svg", target: "albums" },
            { label: qsTr("Artists"), icon: "qrc:/qml/icons/mic.svg", target: "artists" },
            { label: qsTr("Settings"), icon: "qrc:/qml/icons/settings.svg", target: "settings" }
        ]
    }

    function normalizeGeometry(x, y, width, height) {
        const rawScreens = Qt.application.screens || [];
        const screenAreas = [];
        for (let i = 0; i < rawScreens.length; ++i) {
            const screen = rawScreens[i];
            if (screen && screen.availableGeometry)
                screenAreas.push(screen.availableGeometry);
        }

        let clampedWidth = Math.max(width, win.minimumWidth);
        let clampedHeight = Math.max(height, win.minimumHeight);
        const fallback = { x: x, y: y, width: clampedWidth, height: clampedHeight };

        if (screenAreas.length === 0)
            return fallback;

        function isValidGeometry(area) {
            return area
                && typeof area.x === "number"
                && typeof area.y === "number"
                && typeof area.width === "number"
                && typeof area.height === "number"
                && area.width > 0
                && area.height > 0;
        }

        function contains(area, pointX, pointY) {
            return isValidGeometry(area)
                && pointX >= area.x && pointX <= area.x + area.width
                && pointY >= area.y && pointY <= area.y + area.height;
        }

        const primary = screenAreas.find(isValidGeometry);
        if (!primary)
            return fallback;

        // Prefer the screen that contains the saved top-left corner.
        let targetArea = primary;
        for (let i = 0; i < screenAreas.length; ++i) {
            const area = screenAreas[i];
            if (contains(area, x, y)) {
                targetArea = area;
                break;
            }
        }

        if (!isValidGeometry(targetArea))
            return fallback;

        // If the top-left corner was outside of any screen, fall back to centering on the primary screen.
        if (!contains(targetArea, x, y)) {
            return {
                x: primary.x + Math.max(0, (primary.width - clampedWidth) / 2),
                y: primary.y + Math.max(0, (primary.height - clampedHeight) / 2),
                width: Math.min(clampedWidth, primary.width),
                height: Math.min(clampedHeight, primary.height)
            };
        }

        const maxX = typeof targetArea.x === "number" && typeof targetArea.width === "number"
            ? targetArea.x + targetArea.width - clampedWidth
            : x;
        const maxY = typeof targetArea.y === "number" && typeof targetArea.height === "number"
            ? targetArea.y + targetArea.height - clampedHeight
            : y;

        const targetX = typeof targetArea.x === "number" ? targetArea.x : x;
        const targetY = typeof targetArea.y === "number" ? targetArea.y : y;
        const targetWidth = typeof targetArea.width === "number" ? targetArea.width : clampedWidth;
        const targetHeight = typeof targetArea.height === "number" ? targetArea.height : clampedHeight;

        return {
            x: Math.min(Math.max(x, targetX), Math.max(targetX, maxX)),
            y: Math.min(Math.max(y, targetY), Math.max(targetY, maxY)),
            width: Math.min(clampedWidth, targetWidth),
            height: Math.min(clampedHeight, targetHeight)
        };
    }

    function restoreWindowState() {
        if (!windowStateManager || windowStateRestored)
            return
        const defaults = { x: win.x, y: win.y, width: win.width, height: win.height }
        const state = windowStateManager.loadState(defaults.x, defaults.y, defaults.width, defaults.height, win.visibility === Window.Maximized)

        if (state && state.stored) {
            if (state.maximized) {
                win.visibility = Window.Maximized
            } else {
                const geometry = normalizeGeometry(state.x, state.y, state.width, state.height)
                win.width = geometry.width
                win.height = geometry.height
                win.x = geometry.x
                win.y = geometry.y
            }
        }

        windowStateRestored = true
    }

    function saveWindowState() {
        if (!windowStateManager)
            return
        var isMaximized = win.visibility === Window.Maximized || win.visibility === Window.FullScreen
        var geom = null
        if (isMaximized) {
            geom = win.normalGeometry
            if (!geom || typeof geom.x !== "number" || typeof geom.y !== "number" ||
                    typeof geom.width !== "number" || typeof geom.height !== "number") {
                geom = Qt.rect(win.x, win.y, win.width, win.height)
            }
        } else {
            geom = Qt.rect(win.x, win.y, win.width, win.height)
        }
        if (!isMaximized && (geom.width <= 0 || geom.height <= 0)) {
            geom = Qt.rect(win.x, win.y, Math.max(win.width, 1), Math.max(win.height, 1))
        }
        if (!geom || typeof geom.x !== "number" || typeof geom.y !== "number") {
            // As a last resort store the current window rect
            geom = { x: win.x, y: win.y, width: win.width, height: win.height }
        }
        windowStateManager.saveState(geom.x, geom.y, geom.width, geom.height, isMaximized)
    }
    
    property var navigationItems: getNavigationItems()
    property string currentSection: "home"
    property bool initialLibraryLoaded: false
    property bool hasStoredCredentials: false
    property bool windowStateRestored: false

    Connections {
        target: translationManager
        function onLanguageChanged() {
            win.navigationItems = win.getNavigationItems()
        }
    }
    
    Connections {
        target: api
        function onLoginFailed(message) {
            win.hasStoredCredentials = false
            Qt.callLater(function() {
                if (loginLoader.item && loginLoader.item.showError)
                    loginLoader.item.showError(message)
            })
        }
    }

    Loader {
        id: loginLoader
        anchors.fill: parent
        source: win.loginPageUrl
        active: (!api || !api.authenticated) && !hasStoredCredentials
        visible: active
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: api ? api.authenticated : false
        enabled: visible

        RowLayout {
            id: appLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 24
            spacing: 24

            Rectangle {
                id: sidebar
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                radius: 24
                color: "#181d2b"
                border.color: "#1f2536"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 24

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        spacing: 4
                        Label {
                            text: qsTr("Shiba")
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            color: "#f5f7ff"
                            Layout.fillWidth: true
                        }
                        Label {
                            text: qsTr("Music Player")
                            color: "#a0aac6"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    ListView {
                        id: sidebarList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        interactive: false
                        clip: true
                        model: win.navigationItems
                        
                        // Disable all animations to prevent jumping
                        add: null
                        addDisplaced: null
                        remove: null
                        removeDisplaced: null
                        move: null
                        moveDisplaced: null
                        delegate: ItemDelegate {
                            id: navItem
                            width: sidebarList.width
                            height: 44
                            hoverEnabled: true
                            highlighted: modelData.target === win.currentSection
                            background: Rectangle {
                                radius: 12
                                color: navItem.highlighted ? "#2d3650"
                                       : navItem.hovered ? "#242c40" : "transparent"
                                border.color: navItem.highlighted ? "#3b4764" : "transparent"
                            }
                            contentItem: Item {
                                anchors.fill: parent
                                Row {
                                    id: navRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12
                                    Image {
                                        source: modelData.icon
                                        sourceSize.width: 18
                                        sourceSize.height: 18
                                        antialiasing: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label {
                                        text: modelData.label
                                        color: "#d9e0f2"
                                        font.pixelSize: 15
                                        verticalAlignment: Text.AlignVCenter
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                            onClicked: win.handleNavigation(modelData.target)
                        }
                    }

                    Button {
                        text: qsTr("Logout")
                        visible: api ? api.authenticated : false
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        onClicked: {
                            api.logout()
                            win.currentSection = "home"
                        }
                    }
                }
            }

            Rectangle {
                id: mainSurface
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24
                color: "#1b2031"
                border.color: "#232a3f"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 24

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        TextField {
                            id: searchBox
                            Layout.fillWidth: true
                            leftPadding: 32
                            rightPadding: clearButton.visible ? clearButton.width + 8 : 16
                            placeholderText: qsTr("Search songs, artists or albums")
                            font.pixelSize: 14
                            background: Rectangle {
                                radius: 18
                                color: "#141925"
                                border.color: "#2a3148"
                            }
                            Image {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                source: "qrc:/qml/icons/search.svg"
                                sourceSize.width: 16
                                sourceSize.height: 16
                                antialiasing: true
                            }
                            ToolButton {
                                id: clearButton
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                icon.source: "qrc:/qml/icons/close.svg"
                                icon.width: 16
                                icon.height: 16
                                visible: searchBox.text.length > 0
                                onClicked: {
                                    searchBox.clear()
                                    win.performSearch("")
                                }
                            }
                            onAccepted: win.performSearch(text)
                        }

                        Button {
                            text: qsTr("Refresh")
                            onClicked: {
                                switch (win.currentSection) {
                                    case "home":
                                        api.fetchRandomSongs();
                                        break;
                                    case "artists":
                                        api.fetchArtists();
                                        break;
                                    case "albums":
                                        api.fetchAlbumList();
                                        break;
                                    case "favorites":
                                        api.fetchFavorites();
                                        break;
                                }
                            }
                        }
                    }

                    StackView {
                        id: stack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        pushEnter: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                            NumberAnimation { property: "x"; from: width * 0.08; to: 0; duration: 220; easing.type: Easing.OutCubic }
                        }
                        popExit: Transition {
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
                            NumberAnimation { property: "x"; from: 0; to: width * 0.08; duration: 180; easing.type: Easing.InCubic }
                        }
                                          Component.onCompleted: {
                            if (api && api.authenticated && depth === 0) {
                                var page = push(win.homePageUrl)
                                if (page && page.albumClicked)
                                    page.albumClicked.connect(win.showAlbumPage)
                                if (page && page.artistClicked)
                                    page.artistClicked.connect(win.showArtistPage)
                                win.currentSection = "home"
                            }
                        }
                    }
                }
            }
        }

        Components.NowPlayingBar {
            Layout.fillWidth: true
            z: 999
            onQueueRequested: queueOverlay.visible = true
        }
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: 110
        z: 1
        clip: true
        
        Loader {
            id: queueOverlay
            anchors.fill: parent
            visible: false
            active: visible
            source: visible ? Qt.resolvedUrl("qrc:/qml/pages/QueuePage.qml") : ""
            
            Connections {
                target: queueOverlay.item
                function onCloseRequested() {
                    queueOverlay.visible = false
                }
            }
        }
    }

    Component {
        id: placeholderComponent
        Page {
            property string titleText: "Em breve"
            property string descriptionText: "Conteúdo em desenvolvimento."
            background: Rectangle { color: "transparent" }
            Column {
                anchors.centerIn: parent
                spacing: 12
                Label {
                    text: titleText
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    color: "#f5f7ff"
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: descriptionText
                    color: "#a0aac6"
                    font.pixelSize: 14
                    width: 360
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

        Component {
        id: queueComponent
        Page {
            background: Rectangle { color: "transparent" }
            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                anchors.topMargin: 32
                anchors.bottomMargin: 32
                spacing: 18
                Label {
                    text: qsTr("Your queue")
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    color: "#f5f7ff"
                    Layout.leftMargin: 32
                }
                Label {
                    visible: !player.queue || player.queue.length === 0
                    text: qsTr("No tracks in queue. Add songs using the + button.")
                    color: "#a0aac6"
                    font.pixelSize: 14
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: player && player.queue ? player.queue : []
                    delegate: Rectangle {
                        width: parent.width
                        height: 64
                        radius: 12
                        color: mainQueueHover.hovered ? "#273040" : (index % 2 === 0 ? "#1b2336" : "#182030")
                        border.color: mainQueueHover.hovered ? "#3b465f" : "#252e42"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        
                        HoverHandler {
                            id: mainQueueHover
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 8
                                color: "#101622"
                                clip: true
                                
                                Image {
                                    anchors.fill: parent
                                    source: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 128) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: modelData.coverArt && status !== Image.Error
                                }
                                
                                Image {
                                    anchors.centerIn: parent
                                    visible: !modelData.coverArt
                                    source: "qrc:/qml/icons/music_note.svg"
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    antialiasing: true
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title || "Faixa desconhecida"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#f5f7ff"
                                    elide: Label.ElideRight
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.artist || "-"
                                    color: "#8fa0c2"
                                    font.pixelSize: 12
                                    elide: Label.ElideRight
                                }
                            }
                            
                            Row {
                                spacing: 6
                                
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/play_arrow.svg"
                                    onClicked: player.playFromQueue(index)
                                }
                                
                                ToolButton {
                                    icon.source: "qrc:/qml/icons/close.svg"
                                    onClicked: player.removeFromQueue(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: api
        function onAuthenticatedChanged() {
            if (api.authenticated) {
                loginLoader.active = false
                win.initialLibraryLoaded = false
                win.currentSection = "home"
                pushContent(win.homePageUrl)
                api.fetchArtists()
            } else {
                win.initialLibraryLoaded = false
                win.hasStoredCredentials = false
                loginLoader.active = true
                stack.clear()
                win.currentSection = "home"
            }
        }
        function onArtistsChanged() {
            if (!win.initialLibraryLoaded && api.artists.length > 0) {
                api.fetchArtist(api.artists[0].id)
            }
        }
        function onAlbumsChanged() {
            if (!win.initialLibraryLoaded && api.albums.length > 0) {
                api.fetchAlbum(api.albums[0].id)
                win.initialLibraryLoaded = true
            }
        }
    }

    function performSearch(text) {
        if (!api || !api.authenticated)
            return

        const query = text ? text.trim() : ""
        var page = null
        if (stack.depth > 0 && stack.currentItem && stack.currentItem.objectName === "homePage") {
            page = stack.currentItem
        } else {
            page = pushContent(win.homePageUrl)
        }

        if (page) {
            if (!query.length) {
                page.searchActive = false
                page.searchQuery = ""
                page.searchLoading = false
                page.searchResults = []
            } else {
                page.searchActive = true
                page.searchQuery = query
                page.searchLoading = true
                page.searchResults = []
                if (api)
                    api.search(query)
            }
        } else if (query.length && api) {
            api.search(query)
        }

        win.currentSection = "home"
    }

    function handleNavigation(target) {
        if (!api || !api.authenticated)
            return
        win.currentSection = target

        // Clear search when navigating to a different page
        searchBox.clear()

        stack.clear()

        switch (target) {
        case "home":
            var page = stack.push(win.homePageUrl)
            if (page && page.albumClicked)
                page.albumClicked.connect(showAlbumPage)
            if (page && page.artistClicked)
                page.artistClicked.connect(showArtistPage)
            break
        case "playlists":
            stack.push(Qt.resolvedUrl("qrc:/qml/pages/PlaylistsPage.qml"))
            break
        case "favorites":
            stack.push(win.favoritesPageUrl)
            break
        case "albums":
            var page = stack.push(win.albumsPageUrl)
            if (page && page.albumClicked)
                page.albumClicked.connect(showAlbumPage)
            break
        case "artists":
            var page = stack.push(win.artistsPageUrl)
            if (page && page.artistClicked)
                page.artistClicked.connect(showArtistPage)
            break
        case "queue":
            stack.push(queueComponent)
            break
        case "settings":
            stack.push(Qt.resolvedUrl("qrc:/qml/pages/SettingsPage.qml"))
            break
        default:
            break
        }
    }

        function pushContent(target) {
        var page
        if (stack.depth === 0) {
            page = stack.push(target)
        } else {
            page = stack.replace(target)
        }
        // Conectar sinais após o push/replace
        if (page && page.albumClicked)
            page.albumClicked.connect(win.showAlbumPage)
        if (page && page.artistClicked)
            page.artistClicked.connect(win.showArtistPage)
        return page
    }

    function showPlaceholder(title, description) {
        pushContent({
            item: placeholderComponent,
            properties: {
                titleText: title,
                descriptionText: description
            }
        })
    }

    function showArtistPage(artistId, artistName, coverArtId) {
        // Clear search when navigating to artist page
        searchBox.clear()
        
        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/ArtistPage.qml"))
        page.artistId = artistId
        page.artistName = artistName
        page.coverArtId = coverArtId
        if (page && page.albumClicked) {
            page.albumClicked.connect(showAlbumPage)
        }
    }

    function showAlbumPage(albumId, albumTitle, artistName, coverArtId, artistId) {
        // Clear search when navigating to album page
        searchBox.clear()
        
        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/AlbumPage.qml"), {
            albumId: albumId,
            albumTitle: albumTitle,
            artistName: artistName,
            coverArtId: coverArtId,
            artistId: artistId || ""
        })
        // navigation to artist page handled internally by AlbumPage via StackView.view
    }

    function showPlaylistPage(playlistId, playlistName, coverArtId, songCount) {
        // Clear search when navigating to playlist page
        searchBox.clear()
        
        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/PlaylistDetailPage.qml"))
        page.playlistId = playlistId
        page.playlistName = playlistName
        page.coverArtId = coverArtId
        page.songCount = songCount
    }

    Shortcut {
        sequences: [StandardKey.Find, StandardKey.Search]
        onActivated: if (api && api.authenticated) searchBox.forceActiveFocus()
    }

    Timer {
        id: windowStateSaveTimer
        interval: 500
        repeat: false
        onTriggered: saveWindowState()
    }

    Timer {
        id: autoLoginTimer
        interval: 100
        running: false
        onTriggered: {
            if (!api) {
                hasStoredCredentials = false
                return
            }
            var credentials = api.loadCredentials();
            if (credentials.serverUrl && credentials.username && credentials.password) {
                api.login(credentials.serverUrl, credentials.username, credentials.password);
            } else {
                hasStoredCredentials = false
            }
        }
    }

    Components.UpdateDialog {
        id: updateDialog
        checker: updateChecker
    }

    Connections {
        target: updateChecker
        function onUpdateAvailableChanged() {
            if (updateChecker.updateAvailable && api && api.authenticated) {
                updateDialog.open()
            }
        }
    }

    Timer {
        id: updateCheckTimer
        interval: 3000
        running: false
        onTriggered: updateChecker.checkForUpdates()
    }

    Component.onCompleted: {
        restoreWindowState()
        win.visible = true
        win.requestActivate()
        
        if (api) {
            var credentials = api.loadCredentials();
            hasStoredCredentials = !!(credentials.serverUrl && credentials.username && credentials.password)
        } else {
            hasStoredCredentials = false
        }
        autoLoginTimer.start()
        updateCheckTimer.start()
    }

    onXChanged: {
        if (windowStateRestored && visible)
            windowStateSaveTimer.restart()
    }

    onYChanged: {
        if (windowStateRestored && visible)
            windowStateSaveTimer.restart()
    }

    onWidthChanged: {
        if (windowStateRestored && visible && win.visibility !== Window.Maximized)
            windowStateSaveTimer.restart()
    }

    onHeightChanged: {
        if (windowStateRestored && visible && win.visibility !== Window.Maximized)
            windowStateSaveTimer.restart()
    }

    onVisibilityChanged: function(newVisibility) {
        if (!windowStateRestored)
            return
        if (newVisibility === Window.Maximized || newVisibility === Window.Windowed)
            windowStateSaveTimer.restart()
    }

    onClosing: function(event) {
        windowStateSaveTimer.stop()
        saveWindowState()
        event.accepted = true
    }
}
