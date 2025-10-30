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
        { label: "Início", icon: "🏠", target: "home" },
        { label: "Favoritos", icon: "⭐", target: "favorites" },
        { label: "Álbuns", icon: "💿", target: "albums" },
        { label: "Artistas", icon: "🎤", target: "artists" },
        { label: "Fila", icon: "🎵", target: "queue" }
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

    RowLayout {
        id: appLayout
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24
        visible: api.authenticated
        enabled: visible

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
                    Layout.fillHeight: true
                    spacing: 6
                    interactive: false
                    model: win.navigationItems
                    delegate: ItemDelegate {
                        id: navItem
                        width: sidebarList.width
                        padding: 10
                        hoverEnabled: true
                        highlighted: modelData.target === win.currentSection
                        background: Rectangle {
                            radius: 12
                            color: navItem.highlighted ? "#2d3650"
                                   : navItem.hovered ? "#242c40" : "transparent"
                            border.color: navItem.highlighted ? "#3b4764" : "transparent"
                        }
                        contentItem: RowLayout {
                            spacing: 12
                            Label {
                                text: modelData.icon
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label {
                                text: modelData.label
                                color: "#d9e0f2"
                                font.pixelSize: 15
                                Layout.alignment: Qt.AlignVCenter
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
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🔍"
                            color: "#7a859f"
                        }
                        ToolButton {
                            id: clearButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
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
                            api.fetchArtists()
                            if (player.queue && player.queue.length === 0 && api.tracks.length > 0)
                                player.playTrack(api.tracks[0])
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
                            push(win.homePageUrl)
                            win.currentSection = "home"
                        }
                    }
                }
            }
        }

        Components.NowPlayingPanel {
            id: nowPlayingPanel
            Layout.preferredWidth: 320
            Layout.fillHeight: true
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
                anchors.margins: 32
                spacing: 18
                Label {
                    text: "Sua fila"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    color: "#f5f7ff"
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
                        height: 60
                        radius: 14
                        color: index % 2 === 0 ? "#1b2336" : "#182030"
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14
                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 10
                                color: "#101622"
                                Image {
                                    anchors.fill: parent
                                    source: modelData.coverArt ? api.coverArtUrl(modelData.coverArt, 128) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: modelData.coverArt && status !== Image.Error
                                }
                                Label {
                                    anchors.centerIn: parent
                                    visible: !modelData.coverArt
                                    text: "♪"
                                    color: "#55617b"
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    text: modelData.title || "Faixa desconhecida"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Label.ElideRight
                                }
                                Label {
                                    text: modelData.artist || "-"
                                    color: "#8fa0c2"
                                    font.pixelSize: 12
                                    elide: Label.ElideRight
                                }
                            }
                            ToolButton {
                                text: "▶"
                                onClicked: player.playFromQueue(index)
                            }
                            ToolButton {
                                text: "✕"
                                onClicked: player.removeFromQueue(index)
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
        switch (target) {
        case "home":
            pushContent(win.homePageUrl)
            if (stack.currentItem && stack.currentItem.albumClicked)
                stack.currentItem.albumClicked.connect(showAlbumPage)
            break
        case "favorites":
            pushContent(win.favoritesPageUrl)
            break
        case "albums":
            pushContent(win.albumsPageUrl)
            if (stack.currentItem && stack.currentItem.albumClicked)
                stack.currentItem.albumClicked.connect(showAlbumPage)
            break
        case "artists":
            pushContent(win.artistsPageUrl)
            if (stack.currentItem && stack.currentItem.artistClicked)
                stack.currentItem.artistClicked.connect(showArtistPage)
            break
        case "queue":
            pushContent(queueComponent)
            break
        default:
            break
        }
    }

    function pushContent(target) {
        if (stack.depth === 0) {
            return stack.push(target)
        } else {
            return stack.replace(target)
        }
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