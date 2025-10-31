import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "components" as Components

ApplicationWindow {
    id: win
    width: 1360
    height: 840
    minimumWidth: 1080
    minimumHeight: 720
    visible: true
    color: "#11141a"
    title: "Shiba Music"
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

    property var navigationItems: [
        { label: "Início", icon: "qrc:/qml/icons/home.svg", target: "home" },
        { label: "Favoritos", icon: "qrc:/qml/icons/star.svg", target: "favorites" },
        { label: "Álbuns", icon: "qrc:/qml/icons/album.svg", target: "albums" },
        { label: "Artistas", icon: "qrc:/qml/icons/mic.svg", target: "artists" },
        { label: "Configurações", icon: "qrc:/qml/icons/settings.svg", target: "settings" }
    ]
    property string currentSection: "home"
    property bool initialLibraryLoaded: false

    Loader {
        id: loginLoader
        anchors.fill: parent
        source: win.loginPageUrl
        active: !api.authenticated
        visible: active
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: api.authenticated
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
                        spacing: 4
                        Label {
                            text: "Shiba"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            color: "#f5f7ff"
                        }
                        Label {
                            text: "Music Player"
                            color: "#a0aac6"
                            font.pixelSize: 12
                        }
                    }

                    ListView {
                        id: sidebarList
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        spacing: 6
                        interactive: false
                        clip: true
                        model: win.navigationItems
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
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12
                                Image {
                                    source: modelData.icon
                                    sourceSize.width: 18
                                    sourceSize.height: 18
                                    antialiasing: true
                                }
                                Label {
                                    text: modelData.label
                                    color: "#d9e0f2"
                                    font.pixelSize: 15
                                    Layout.fillWidth: true
                                }
                            }
                            onClicked: win.handleNavigation(modelData.target)
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: "Sair"
                        visible: api.authenticated
                        Layout.fillWidth: true
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
                            rightPadding: clearButton.visible ? clearButton.implicitWidth + 16 : 16
                            placeholderText: "Buscar músicas, artistas ou álbuns"
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
                                icon.source: "qrc:/qml/icons/close.svg"
                                visible: searchBox.text.length > 0
                                onClicked: {
                                    searchBox.clear()
                                    api.search("")
                                }
                            }
                            onAccepted: win.performSearch(text)
                        }

                        Button {
                            text: "Atualizar"
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
                            if (api.authenticated && depth === 0) {
                                var page = push(win.homePageUrl)
                                if (page && page.albumClicked)
                                    page.albumClicked.connect(win.showAlbumPage)
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
                    text: "Sua fila"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    color: "#f5f7ff"
                    Layout.leftMargin: 32
                }
                Label {
                    visible: !player.queue || player.queue.length === 0
                    text: "Nenhuma faixa na fila. Adicione músicas usando o botão +."
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
                        color: index % 2 === 0 ? "#1b2336" : "#182030"
                        border.color: "#252e42"
                        
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
        if (!api.authenticated || !text || !text.length)
            return
        api.search(text)
        pushContent(win.homePageUrl)
        win.currentSection = "home"
    }

    function handleNavigation(target) {
        if (!api.authenticated)
            return
        win.currentSection = target

        stack.clear()

        switch (target) {
        case "home":
            var page = stack.push(win.homePageUrl)
            if (page && page.albumClicked)
                page.albumClicked.connect(showAlbumPage)
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
        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/ArtistPage.qml"))
        page.artistId = artistId
        page.artistName = artistName
        page.coverArtId = coverArtId
        if (page && page.albumClicked) {
            page.albumClicked.connect(showAlbumPage)
        }
    }

    function showAlbumPage(albumId, albumTitle, artistName, coverArtId) {
        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/AlbumPage.qml"))
        page.albumId = albumId
        page.albumTitle = albumTitle
        page.artistName = artistName
        page.coverArtId = coverArtId
    }

    Shortcut {
        sequences: [StandardKey.Find, StandardKey.Search]
        onActivated: if (api.authenticated) searchBox.forceActiveFocus()
    }

    Component.onCompleted: {
        var credentials = api.loadCredentials();
        if (credentials.serverUrl && credentials.username && credentials.password) {
            api.login(credentials.serverUrl, credentials.username, credentials.password);
        }
    }
}