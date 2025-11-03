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
    Components.ThemePalette { id: theme }
    readonly property bool materialTheme: theme.isMaterial
    readonly property bool micaTheme: theme.isMica
    readonly property bool gtkTheme: theme.isGtk
    readonly property string currentThemeId: theme.themeId
    readonly property bool darkTheme: theme.isDark
    color: theme.windowBackgroundFallback
    title: qsTr("Shiba Music")
    Material.theme: darkTheme ? Material.Dark : Material.Light
    Material.accent: currentThemeId === "material" ? Material.Indigo : Material.BlueGrey
    font.family: theme.fontFamily

    readonly property url homePageUrl: Qt.resolvedUrl("qrc:/qml/pages/HomePage.qml")
    readonly property url loginPageUrl: Qt.resolvedUrl("qrc:/qml/pages/LoginPage.qml")
    readonly property url artistsPageUrl: Qt.resolvedUrl("qrc:/qml/pages/ArtistsPage.qml")
    readonly property url albumsPageUrl: Qt.resolvedUrl("qrc:/qml/pages/AlbumsPage.qml")
    readonly property url favoritesPageUrl: Qt.resolvedUrl("qrc:/qml/pages/FavoritesPage.qml")

    background: Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            visible: gtkTheme
            color: theme.windowBackgroundFallback
        }

        Rectangle {
            anchors.fill: parent
            visible: !gtkTheme
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.windowBackgroundStart }
                GradientStop { position: 1.0; color: theme.windowBackgroundEnd }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: micaTheme
            color: theme.windowBackgroundFallback
            opacity: 0.85
        }

        Rectangle {
            anchors.fill: parent
            visible: micaTheme
            color: theme.shadow
            opacity: 0.12
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

    function restoreWindowState() {
        if (!windowStateManager || windowStateRestored)
            return
        const defaults = { x: win.x, y: win.y, width: win.width, height: win.height }
        const state = windowStateManager.loadState(
                    defaults.x, defaults.y, defaults.width, defaults.height,
                    win.visibility === Window.Maximized, win.minimumWidth, win.minimumHeight)

        pendingMaximizeRestore = false

        if (state && state.stored) {
            win.width = state.width
            win.height = state.height
            win.x = state.x
            win.y = state.y
            lastWindowedGeometry = Qt.rect(state.x, state.y, state.width, state.height)
            pendingMaximizeRestore = state.maximized
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
                if (lastWindowedGeometry) {
                    geom = lastWindowedGeometry
                } else {
                    geom = Qt.rect(win.x, win.y, win.width, win.height)
                }
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

    function captureWindowedGeometry() {
        if (win.visibility !== Window.Maximized && win.visibility !== Window.FullScreen) {
            lastWindowedGeometry = Qt.rect(win.x, win.y, win.width, win.height)
        }
    }

    function normalizeServerUrl(value) {
        var trimmed = (value || "").trim()
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.slice(0, -1)
        }
        return trimmed
    }

    function normalizeUsername(value) {
        return (value || "").trim()
    }

    function credentialKeyFor(url, username) {
        var normalizedUrl = normalizeServerUrl(url)
        var normalizedUser = normalizeUsername(username)
        if (!normalizedUrl.length || !normalizedUser.length)
            return ""
        return normalizedUrl.toLowerCase() + "|" + normalizedUser.toLowerCase()
    }

    function savedCredentialIndex(key) {
        if (!key || !savedServerProfiles || !savedServerProfiles.length)
            return -1
        for (var i = 0; i < savedServerProfiles.length; ++i) {
            var entry = savedServerProfiles[i]
            if (!entry)
                continue
            var entryKey = entry.key || credentialKeyFor(entry.serverUrl, entry.username)
            if (entryKey && entryKey === key)
                return i
        }
        return -1
    }

    function toPlainString(value) {
        if (value === undefined || value === null)
            return ""
        return String(value)
    }

    function mappedCredential(entry) {
        if (!entry)
            return null
        var server = normalizeServerUrl(entry.serverUrl)
        var user = normalizeUsername(entry.username)
        var key = entry.key || credentialKeyFor(server, user)
        if (!key)
            return null
        var label = entry.displayName
        if (!label || !label.length) {
            label = user.length ? user + " @ " + server : server
        }
        return {
            key: key,
            serverUrl: server,
            username: user,
            password: toPlainString(entry.password),
            displayName: label,
            lastUsed: toPlainString(entry.lastUsed)
        }
    }

    function refreshSavedCredentials(preferredKey) {
        var list = []
        if (api && api.savedCredentials) {
            var fetched = api.savedCredentials()
            if (fetched && fetched.length !== undefined) {
                for (var i = 0; i < fetched.length; ++i) {
                    var mapped = mappedCredential(fetched[i])
                    if (mapped)
                        list.push(mapped)
                }
            }
        }

        savedServerProfiles = list

        var key = preferredKey || activeCredentialKey
        if (!key && api && api.loadCredentials) {
            var current = api.loadCredentials()
            if (current) {
                key = current.key || credentialKeyFor(current.serverUrl, current.username)
            }
        }
        if (!key && api && api.serverUrl && api.username) {
            key = credentialKeyFor(api.serverUrl, api.username)
        }

        activeCredentialKey = key || ""

        if (typeof serverSelector !== "undefined") {
            serverSelector.currentIndex = savedCredentialIndex(activeCredentialKey)
        }
    }

    function connectUsingCredential(entry) {
        if (!entry || !api)
            return

        var serverUrl = normalizeServerUrl(entry.serverUrl)
        var username = normalizeUsername(entry.username)
        var password = toPlainString(entry.password)

        if (!serverUrl.length || !username.length || !password.length) {
            return
        }

        var key = entry.key || credentialKeyFor(serverUrl, username)

        switchingServer = api.authenticated
        activeCredentialKey = key
        hasStoredCredentials = true
        loginLoader.active = false

        if (api.saveCredentials) {
            api.saveCredentials(serverUrl, username, password, true)
        }

        if (api.authenticated && api.logout) {
            api.logout()
        }

        api.login(serverUrl, username, password)
        refreshSavedCredentials(key)
    }

    function selectServerByIndex(index) {
        if (index < 0 || index >= (savedServerProfiles ? savedServerProfiles.length : 0))
            return
        connectUsingCredential(savedServerProfiles[index])
    }
    
    property var navigationItems: getNavigationItems()
    property string currentSection: "home"
    property bool initialLibraryLoaded: false
    property bool hasStoredCredentials: false
    property bool windowStateRestored: false
    property var savedServerProfiles: []
    property string activeCredentialKey: ""
    property bool switchingServer: false
    property var navigationHistory: []
    property var forwardHistory: []
    property bool pendingMaximizeRestore: false
    property var lastWindowedGeometry: Qt.rect(x, y, width, height)

    onSavedServerProfilesChanged: {
        if (typeof serverSelector !== "undefined") {
            serverSelector.currentIndex = savedCredentialIndex(activeCredentialKey)
        }
    }

    onActiveCredentialKeyChanged: {
        if (typeof serverSelector !== "undefined") {
            serverSelector.currentIndex = savedCredentialIndex(activeCredentialKey)
        }
    }

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
            win.switchingServer = false
            win.refreshSavedCredentials(win.activeCredentialKey)
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
            Layout.margins: theme.paddingPanel
            spacing: theme.spacing3xl

            Rectangle {
                id: sidebar
                Layout.preferredWidth: gtkTheme ? 208 : 220
                Layout.fillHeight: true
                radius: gtkTheme ? theme.radiusCard : theme.radiusPanel
                color: micaTheme ? Qt.tint(theme.surface, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.08)) : theme.surface
                opacity: micaTheme ? 0.94 : 1
                border.color: theme.surfaceBorder
                border.width: gtkTheme ? theme.borderWidthThin : (micaTheme ? theme.borderWidthThin : 0)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: theme.borderWidthThin
                    color: theme.divider
                    visible: gtkTheme
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(theme.toolbarBackground.r, theme.toolbarBackground.g, theme.toolbarBackground.b, micaTheme ? 0.4 : 0.2) }
                        GradientStop { position: 0.4; color: "transparent" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    visible: micaTheme
                    opacity: 0.7
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: theme.shadow
                    opacity: micaTheme ? 0.25 : 0
                    visible: micaTheme
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: gtkTheme ? theme.spacingXl : theme.paddingPanel
                    spacing: gtkTheme ? theme.spacingXl : theme.spacing3xl

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        spacing: gtkTheme ? theme.spacingSm : theme.spacingMd

                        ToolButton {
                            id: sidebarBackButton
                            implicitWidth: 40
                            implicitHeight: 36
                    background: Rectangle {
                        anchors.fill: parent
                        radius: theme.radiusButton
                        color: gtkTheme ? "transparent" : sidebarBackButton.hovered ? theme.surfaceInteractive : "transparent"
                        border.color: gtkTheme ? "transparent" : sidebarBackButton.hovered ? theme.surfaceInteractiveBorder : "transparent"
                    }
                            padding: 0
                            opacity: enabled ? 1.0 : theme.opacityDisabled
                            hoverEnabled: true
                            contentItem: Components.ColoredIcon {
                                anchors.centerIn: parent
                                source: "qrc:/qml/icons/chevron_left.svg"
                                width: theme.iconSizeMedium
                                height: theme.iconSizeMedium
                                smooth: true
                                color: sidebarBackButton.enabled ? theme.textPrimary : theme.textSecondary
                                opacity: sidebarBackButton.enabled ? 1.0 : 0.35
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Go back")
                            onClicked: win.goBack()
                            enabled: win.canGoBack()
                        }

                        ToolButton {
                            id: sidebarForwardButton
                            implicitWidth: 40
                            implicitHeight: 36
                    background: Rectangle {
                        anchors.fill: parent
                        radius: theme.radiusButton
                        color: gtkTheme ? "transparent" : sidebarForwardButton.hovered ? theme.surfaceInteractive : "transparent"
                        border.color: gtkTheme ? "transparent" : sidebarForwardButton.hovered ? theme.surfaceInteractiveBorder : "transparent"
                    }
                            padding: 0
                            opacity: enabled ? 1.0 : theme.opacityDisabled
                            hoverEnabled: true
                            contentItem: Components.ColoredIcon {
                                anchors.centerIn: parent
                                source: "qrc:/qml/icons/chevron_right.svg"
                                width: theme.iconSizeMedium
                                height: theme.iconSizeMedium
                                smooth: true
                                color: sidebarForwardButton.enabled ? theme.textPrimary : theme.textSecondary
                                opacity: sidebarForwardButton.enabled ? 1.0 : 0.35
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Go forward")
                            onClicked: win.goForward()
                            enabled: win.canGoForward()
                        }

                        Item { Layout.fillWidth: true }
                    }

                    ListView {
                        id: sidebarList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: theme.spacingSm
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
                            background: Item {
                                anchors.fill: parent

                                Rectangle {
                                    anchors.fill: parent
                                    radius: theme.radiusButton
                                    color: navItem.highlighted ? (micaTheme ? Qt.tint(theme.listItemActive, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)) : theme.listItemActive)
                                           : navItem.hovered ? (micaTheme ? Qt.tint(theme.listItemHover, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)) : theme.listItemHover)
                                                             : (micaTheme ? Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.35) : "transparent")
                                    border.color: navItem.highlighted ? theme.accent : "transparent"
                                    border.width: navItem.highlighted ? theme.borderWidthThin : 0
                                    visible: !gtkTheme
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: gtkTheme ? theme.radiusNone : theme.radiusButton
                                    color: gtkTheme && navItem.hovered ? theme.listItemHover : "transparent"
                                    border.width: gtkTheme ? theme.borderWidthThin : 0
                                    border.color: gtkTheme ? (navItem.highlighted ? theme.accent : theme.divider) : "transparent"
                                    visible: gtkTheme
                                }

                                Rectangle {
                                    width: gtkTheme && navItem.highlighted ? 3 : 0
                                    visible: gtkTheme && navItem.highlighted
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    radius: 2
                                    color: theme.accent
                                }
                            }
                            contentItem: Item {
                                anchors.fill: parent
                                    Row {
                                        id: navRow
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: theme.spacingLg
                                        anchors.rightMargin: theme.spacingLg
                                        spacing: gtkTheme ? theme.spacingMd : theme.spacingLg
                                    Components.ColoredIcon {
                                        source: modelData.icon
                                        width: theme.iconSizeMedium
                                        height: theme.iconSizeMedium
                                        smooth: true
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: navItem.highlighted ? theme.accentLight : theme.textSecondary
                                    }
                                    Label {
                                        text: modelData.label
                                        color: navItem.highlighted ? theme.textPrimary : theme.textSecondary
                                        font.pixelSize: theme.fontSizeSubtitle
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

                    Component {
                        id: gtkButtonBackground
                        Rectangle {
                            radius: theme.radiusButton
                            color: theme.surface
                            border.width: theme.borderWidthThin
                            border.color: theme.surfaceBorder
                        }
                    }

                    Button {
                        text: qsTr("Logout")
                        visible: api ? api.authenticated : false
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        flat: gtkTheme
                        background: gtkTheme ? gtkButtonBackground : null
                        onClicked: {
                            win.switchingServer = false
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
                radius: gtkTheme ? theme.radiusCard : theme.radiusPanel
                color: micaTheme ? Qt.tint(theme.surfaceElevated, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.1)) : theme.surfaceElevated
                opacity: micaTheme ? 0.95 : 1
                border.color: theme.surfaceElevatedBorder
                border.width: gtkTheme ? theme.borderWidthThin : (micaTheme ? theme.borderWidthThin : 0)

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(theme.toolbarBackground.r, theme.toolbarBackground.g, theme.toolbarBackground.b, micaTheme ? 0.55 : 0.25) }
                        GradientStop { position: 0.28; color: "transparent" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    visible: micaTheme
                    opacity: 0.85
                    z: -1
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: theme.shadow
                    opacity: micaTheme ? 0.22 : 0
                    visible: micaTheme
                    z: -2
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: theme.borderWidthThin
                    color: theme.divider
                    visible: gtkTheme
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: gtkTheme ? theme.paddingPanel : theme.paddingPage
                    spacing: gtkTheme ? theme.spacingXl : theme.spacing3xl

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: gtkTheme ? theme.spacingLg : theme.spacingXl

                        ColumnLayout {
                            visible: win.savedServerProfiles.length > 0
                            Layout.preferredWidth: 280
                            Layout.maximumWidth: 340
                            Layout.alignment: Qt.AlignVCenter
                            spacing: theme.spacingXs

                            Label {
                                text: qsTr("Server")
                                color: theme.textMuted
                                font.pixelSize: theme.fontSizeCaption
                                visible: parent.visible
                            }

                            ComboBox {
                                id: serverSelector
                                Layout.fillWidth: true
                                model: win.savedServerProfiles
                                textRole: "displayName"
                                displayText: currentIndex >= 0 && currentIndex < win.savedServerProfiles.length
                                        ? win.savedServerProfiles[currentIndex].displayName
                                        : qsTr("Select a server")
                                onActivated: win.selectServerByIndex(index)
                            }
                        }

                        TextField {
                            id: searchBox
                            Layout.fillWidth: true
                            leftPadding: theme.paddingFieldHorizontal + theme.iconSizeSmall
                            rightPadding: clearButton.visible ? clearButton.width + theme.spacingSm : theme.paddingFieldHorizontal
                            placeholderText: qsTr("Search songs, artists or albums")
                            font.pixelSize: theme.fontSizeBody
                            background: Rectangle {
                                radius: theme.radiusInput
                                color: micaTheme ? Qt.tint(theme.surface, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.15)) : theme.surface
                                border.color: micaTheme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25) : theme.surfaceBorder
                                border.width: theme.borderWidthThin
                                opacity: micaTheme ? 0.9 : 1
                            }
                            Components.ColoredIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: theme.spacingLg
                                anchors.verticalCenter: parent.verticalCenter
                                source: "qrc:/qml/icons/search.svg"
                                width: theme.iconSizeSmall
                                height: theme.iconSizeSmall
                                smooth: true
                                color: micaTheme ? Qt.tint(theme.textSecondary, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.35)) : theme.textSecondary
                            }
                            ToolButton {
                                id: clearButton
                                anchors.right: parent.right
                                anchors.rightMargin: theme.spacingXs
                                anchors.verticalCenter: parent.verticalCenter
                                icon.source: "qrc:/qml/icons/close.svg"
                                icon.width: theme.iconSizeSmall
                                icon.height: theme.iconSizeSmall
                                visible: searchBox.text.length > 0
                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: theme.radiusBadge
                                    color: micaTheme ? (clearButton.hovered ? Qt.tint(theme.surfaceInteractive, Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2))
                                                                  : Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.2))
                                                     : "transparent"
                                    border.width: 0
                                }
                                onClicked: {
                                    searchBox.clear()
                                    win.performSearch("")
                                }
                            }
                            onAccepted: win.performSearch(text)
                    }

                    Button {
                        id: refreshButton
                        text: qsTr("Refresh")
                        font.pixelSize: theme.fontSizeBody
                        padding: theme.spacingSm
                        implicitHeight: 36
                        implicitWidth: 120
                        background: Rectangle {
                            radius: theme.radiusButton
                            color: micaTheme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, refreshButton.hovered ? 0.22 : 0.14)
                                             : theme.accent
                            border.width: micaTheme ? theme.borderWidthThin : 0
                            border.color: micaTheme ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45) : "transparent"
                        }
                        contentItem: Label {
                            text: parent.text
                            font: parent.font
                            color: micaTheme ? theme.textPrimary : "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
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
                            enabled: !gtkTheme
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                            NumberAnimation { property: "x"; from: width * 0.08; to: 0; duration: 220; easing.type: Easing.OutCubic }
                        }
                        popExit: Transition {
                            enabled: !gtkTheme
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
                            NumberAnimation { property: "x"; from: 0; to: width * 0.08; duration: 180; easing.type: Easing.InCubic }
                        }
                        Component.onCompleted: {
                            if (api && api.authenticated && depth === 0) {
                                win.loadSection("home", navigationHistory.length === 0)
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
                spacing: theme.spacingLg
                Label {
                    text: titleText
                    font.pixelSize: theme.fontSizeDisplay + theme.spacingXs / 2
                    font.weight: Font.DemiBold
                    color: theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: descriptionText
                    color: theme.textSecondary
                    font.pixelSize: theme.fontSizeBody
                    width: theme.placeholderTextWidth
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
                anchors.topMargin: theme.paddingPage
                anchors.bottomMargin: theme.paddingPage
                spacing: theme.spacing2xl
                Label {
                    text: qsTr("Your queue")
                    font.pixelSize: theme.fontSizeDisplay
                    font.weight: Font.DemiBold
                    color: theme.textPrimary
                    Layout.leftMargin: theme.paddingPage
                }
                Label {
                    visible: !player.queue || player.queue.length === 0
                    text: qsTr("No tracks in queue. Add songs using the + button.")
                    color: theme.textSecondary
                    font.pixelSize: theme.fontSizeBody
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: theme.spacingMd + theme.spacingXs / 2
                    model: player && player.queue ? player.queue : []
                    delegate: Rectangle {
                        width: parent.width
                        height: theme.queueItemHeight
                        radius: theme.radiusButton
                        color: mainQueueHover.hovered ? theme.listItemHover
                              : (index % 2 === 0 ? theme.listItem : theme.listItemAlternate)
                        border.color: mainQueueHover.hovered ? theme.surfaceInteractiveBorder : theme.cardBorder
                        Behavior on color { ColorAnimation { duration: 120 } }
                        
                        HoverHandler {
                            id: mainQueueHover
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: theme.spacingLg
                            spacing: theme.spacingLg
                            
                            Rectangle {
                                Layout.preferredWidth: theme.queueArtworkSize
                                Layout.preferredHeight: theme.queueArtworkSize
                                radius: theme.radiusChip
                                color: theme.surface
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
                                    sourceSize.width: theme.iconSizeMedium
                                    sourceSize.height: theme.iconSizeMedium
                                    antialiasing: true
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: theme.spacingXs / 2
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title || qsTr("Faixa desconhecida")
                                    font.pixelSize: theme.fontSizeBody
                                    font.weight: Font.Medium
                                    color: theme.textPrimary
                                    elide: Label.ElideRight
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.artist || "-"
                                    color: theme.textSecondary
                                    font.pixelSize: theme.fontSizeCaption
                                    elide: Label.ElideRight
                                }
                            }
                            
                            Row {
                                spacing: theme.spacingSm
                                
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
                var key = credentialKeyFor(api.serverUrl, api.username)
                win.refreshSavedCredentials(key)
                win.hasStoredCredentials = true
                win.switchingServer = false
                loginLoader.active = false
                win.initialLibraryLoaded = false
                navigationHistory = []
                forwardHistory = []
                loadSection("home", true)
                api.fetchArtists()
            } else {
                win.initialLibraryLoaded = false
                win.refreshSavedCredentials(win.activeCredentialKey)
                stack.clear()
                win.currentSection = "home"
                navigationHistory = []
                forwardHistory = []
                if (win.switchingServer) {
                    loginLoader.active = false
                    win.hasStoredCredentials = true
                } else {
                    win.hasStoredCredentials = false
                    loginLoader.active = true
                }
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

    function pushHistoryEntry(entry) {
        var last = navigationHistory.length ? navigationHistory[navigationHistory.length - 1] : null
        var same = last && JSON.stringify(last) === JSON.stringify(entry)
        if (!same) {
            navigationHistory = navigationHistory.concat([entry])
        }
    }

    function loadSection(target, recordHistory) {
        if (!api || !api.authenticated)
            return
        if (recordHistory === undefined) recordHistory = true

        if (recordHistory) {
            recordHistoryEntry({kind: "section", target: target})
        }

        win.currentSection = target
        searchBox.clear()
        stack.clear()

        var page = null
        switch (target) {
        case "home":
            page = stack.push(win.homePageUrl)
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
            page = stack.push(win.albumsPageUrl)
            if (page && page.albumClicked)
                page.albumClicked.connect(showAlbumPage)
            break
        case "artists":
            page = stack.push(win.artistsPageUrl)
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

    function handleNavigation(target) {
        loadSection(target, true)
    }

    function restoreEntry(entry) {
        if (!entry) return
        switch (entry.kind) {
        case "section":
            loadSection(entry.target, false)
            break
        case "album":
            showAlbumPage(entry.albumId, entry.albumTitle, entry.artistName, entry.coverArtId, entry.artistId, false)
            break
        case "artist":
            showArtistPage(entry.artistId, entry.artistName, entry.coverArtId, false)
            break
        case "playlist":
            showPlaylistPage(entry.playlistId, entry.playlistName, entry.coverArtId, entry.songCount, false)
            break
        }
    }

    function canGoBack() {
        return navigationHistory.length > 1
    }

    function canGoForward() {
        return forwardHistory.length > 0
    }

    function goBack() {
        if (!canGoBack())
            return
        var historyCopy = navigationHistory.slice()
        var current = historyCopy.pop()
        navigationHistory = historyCopy
        forwardHistory = [JSON.parse(JSON.stringify(current))].concat(forwardHistory)
        trimHistory()
        var entry = navigationHistory.length ? navigationHistory[navigationHistory.length - 1] : null
        if (entry)
            restoreEntry(entry)
    }

    function goForward() {
        if (!canGoForward())
            return
        var entry = forwardHistory[0]
        forwardHistory = forwardHistory.slice(1)
        var entryCopy = JSON.parse(JSON.stringify(entry))
        navigationHistory = navigationHistory.concat([entryCopy])
        trimHistory()
        restoreEntry(entryCopy)
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

    function trimHistory() {
        const maxEntries = 100
        if (navigationHistory.length > maxEntries)
            navigationHistory = navigationHistory.slice(navigationHistory.length - maxEntries)
        if (forwardHistory.length > maxEntries)
            forwardHistory = forwardHistory.slice(forwardHistory.length - maxEntries)
    }

    function recordHistoryEntry(entry) {
        pushHistoryEntry(JSON.parse(JSON.stringify(entry)))
        forwardHistory = []
        trimHistory()
    }

    function showArtistPage(artistId, artistName, coverArtId, recordHistory) {
        if (recordHistory === undefined) recordHistory = true
        // Clear search when navigating to artist page
        searchBox.clear()

        if (!recordHistory) {
            stack.clear()
            win.currentSection = "artists"
        }

        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/ArtistPage.qml"))
        page.artistId = artistId
        page.artistName = artistName
        page.coverArtId = coverArtId
        if (page && page.albumClicked) {
            page.albumClicked.connect(showAlbumPage)
        }

        if (recordHistory) {
            recordHistoryEntry({
                kind: "artist",
                artistId: artistId,
                artistName: artistName,
                coverArtId: coverArtId || ""
            })
        }
    }

    function showAlbumPage(albumId, albumTitle, artistName, coverArtId, artistId, recordHistory) {
        if (recordHistory === undefined) recordHistory = true
        // Clear search when navigating to album page
        searchBox.clear()

        if (!recordHistory) {
            stack.clear()
            win.currentSection = "home"
        }

        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/AlbumPage.qml"), {
            albumId: albumId,
            albumTitle: albumTitle,
            artistName: artistName,
            coverArtId: coverArtId,
            artistId: artistId || ""
        })
        // navigation to artist page handled internally by AlbumPage via StackView.view

        if (recordHistory) {
            recordHistoryEntry({
                kind: "album",
                albumId: albumId,
                albumTitle: albumTitle,
                artistName: artistName,
                coverArtId: coverArtId || "",
                artistId: artistId || ""
            })
        }
    }

    function showPlaylistPage(playlistId, playlistName, coverArtId, songCount, recordHistory) {
        if (recordHistory === undefined) recordHistory = true
        // Clear search when navigating to playlist page
        searchBox.clear()

        if (!recordHistory) {
            stack.clear()
            win.currentSection = "playlists"
        }

        var page = stack.push(Qt.resolvedUrl("qrc:/qml/pages/PlaylistDetailPage.qml"))
        page.playlistId = playlistId
        page.playlistName = playlistName
        page.coverArtId = coverArtId
        page.songCount = songCount

        if (recordHistory) {
            recordHistoryEntry({
                kind: "playlist",
                playlistId: playlistId,
                playlistName: playlistName,
                coverArtId: coverArtId || "",
                songCount: songCount || 0
            })
        }
    }

    Shortcut {
        sequences: [StandardKey.Find, StandardKey.Search]
        onActivated: if (api && api.authenticated) searchBox.forceActiveFocus()
    }
    
    // Media control shortcuts
    Shortcut {
        sequence: "Space"
        onActivated: if (player && player.queue.length > 0) player.toggle()
    }
    
    Shortcut {
        sequence: "Shift+N"
        onActivated: if (player && player.queue.length > 0) player.next()
    }
    
    Shortcut {
        sequence: "Shift+P"
        onActivated: if (player && player.queue.length > 0) player.previous()
    }
    
    Shortcut {
        sequence: "M"
        onActivated: if (player) player.muted = !player.muted
    }
    
    Shortcut {
        sequence: "Up"
        onActivated: if (player) player.volume = Math.min(1.0, player.volume + 0.05)
    }
    
    Shortcut {
        sequence: "Down"
        onActivated: if (player) player.volume = Math.max(0.0, player.volume - 0.05)
    }

    Shortcut {
        sequences: ["Alt+Left", "Back"]
        onActivated: if (win.canGoBack()) win.goBack()
    }

    Shortcut {
        sequences: ["Alt+Right", "Forward"]
        onActivated: if (win.canGoForward()) win.goForward()
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
                refreshSavedCredentials("")
                return
            }
            var credentials = api.loadCredentials();
            if (credentials.serverUrl && credentials.username && credentials.password) {
                var key = credentials.key || credentialKeyFor(credentials.serverUrl, credentials.username)
                refreshSavedCredentials(key)
                switchingServer = false
                api.login(credentials.serverUrl, credentials.username, credentials.password);
            } else {
                hasStoredCredentials = false
                refreshSavedCredentials("")
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
            console.log("UpdateChecker: updateAvailable changed to", updateChecker.updateAvailable)
            if (updateChecker.updateAvailable) {
                console.log("UpdateChecker: Opening update dialog")
                updateDialog.open()
            }
        }
        function onUpdateCheckFailed(error) {
            console.warn("UpdateChecker: Check failed:", error)
        }
        function onIsCheckingChanged() {
            console.log("UpdateChecker: isChecking changed to", updateChecker.isChecking)
        }
        function onAboutToQuit() {
            console.log("UpdateChecker: Application closing for update installation...")
            win.close()
        }
    }

    Timer {
        id: updateCheckTimer
        interval: 3000
        running: false
        onTriggered: {
            console.log("UpdateChecker: Timer triggered, starting check...")
            updateChecker.checkForUpdates()
        }
    }

    Component.onCompleted: {
        restoreWindowState()
        captureWindowedGeometry()
        
        if (pendingMaximizeRestore) {
            win.showMaximized()
            pendingMaximizeRestore = false
        } else {
            win.show()
        }
        
        win.requestActivate()

        if (api) {
            var credentials = api.loadCredentials();
            hasStoredCredentials = !!(credentials.serverUrl && credentials.username && credentials.password)
            var key = credentials.key || credentialKeyFor(credentials.serverUrl, credentials.username)
            refreshSavedCredentials(key)
        } else {
            hasStoredCredentials = false
            refreshSavedCredentials("")
        }
        autoLoginTimer.start()
        updateCheckTimer.start()
    }

    onXChanged: {
        captureWindowedGeometry()
        if (windowStateRestored && visible)
            windowStateSaveTimer.restart()
    }

    onYChanged: {
        captureWindowedGeometry()
        if (windowStateRestored && visible)
            windowStateSaveTimer.restart()
    }

    onWidthChanged: {
        captureWindowedGeometry()
        if (windowStateRestored && visible && win.visibility !== Window.Maximized)
            windowStateSaveTimer.restart()
    }

    onHeightChanged: {
        captureWindowedGeometry()
        if (windowStateRestored && visible && win.visibility !== Window.Maximized)
            windowStateSaveTimer.restart()
    }

    onVisibilityChanged: function(newVisibility) {
        captureWindowedGeometry()
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

