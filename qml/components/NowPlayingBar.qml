import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "qrc:/qml/js/utils.js" as Utils
import "." as Components

Rectangle {
    id: bar
    width: parent ? parent.width : 800
    height: 110

    Components.ThemePalette { id: theme }
    
    gradient: Gradient {
        GradientStop { position: 0.0; color: theme.toolbarBackground }
        GradientStop { position: 1.0; color: theme.surface }
    }
    signal queueRequested()
    readonly property bool hasQueue: (player && player.queue) ? (player.queue.length > 0) : false
    readonly property bool hasTrack: (player && player.currentTrack) ? (!!player.currentTrack.id) : false

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        // Capa do álbum com efeito de brilho
        Item {
            Layout.alignment: Qt.AlignVCenter
            width: 78
            height: 78
            
            Rectangle {
                id: coverContainer
                anchors.centerIn: parent
                width: 78
                height: 78
                radius: 0
                color: theme.surface
                border.color: theme.surfaceBorder
                border.width: 2
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    anchors.margins: 2
                    source: bar.hasTrack ? api.coverArtUrl(player.currentTrack.coverArt, 256) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                // Placeholder quando não há imagem
                Image {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready || !bar.hasTrack
                    source: "../icons/music_note.svg"
                    width: 36
                    height: 36
                    fillMode: Image.PreserveAspectFit
                }

                // Overlay de seta para cima
                Rectangle {
                    anchors.fill: parent
                    color: theme.shadow
                    opacity: coverMouseArea.containsMouse ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    
                    Image {
                        anchors.centerIn: parent
                        source: "../icons/arrow_upward.svg"
                        width: 32
                        height: 32
                        fillMode: Image.PreserveAspectFit
                        opacity: coverMouseArea.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: coverMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.queueRequested()
                }
            }

        }

        // Informações da música e controles
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Título e artista
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    id: titleLabel
                    Layout.fillWidth: true
                    text: bar.hasTrack ? player.currentTrack.title : "Nenhuma música tocando"
                    elide: Label.ElideRight
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: bar.hasTrack ? theme.textPrimary : theme.textSecondary
                    
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton && bar.hasTrack) {
                                trackContextMenu.popup()
                            }
                        }
                    }
                }
                
                Label {
                    Layout.fillWidth: true
                    visible: !bar.hasTrack
                    text: qsTr("Selecione uma música para começar")
                    color: theme.textSecondary
                    font.pixelSize: 13
                    elide: Label.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: bar.hasTrack

                    Item {
                        Layout.fillWidth: !albumWrapper.visible
                        Layout.preferredWidth: artistLabel.implicitWidth
                        height: artistLabel.implicitHeight
                        visible: !!(player.currentTrack && player.currentTrack.artist)

                        Label {
                            id: artistLabel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: player.currentTrack ? (player.currentTrack.artist || "") : ""
                            color: (artistMouseArea.containsMouse && artistMouseArea.enabled) ? theme.textPrimary : theme.textSecondary
                            font.pixelSize: 13
                            elide: Label.ElideRight
                        }

                        MouseArea {
                            id: artistMouseArea
                            anchors.left: parent.left
                            anchors.verticalCenter: artistLabel.verticalCenter
                            width: Math.min(artistLabel.implicitWidth, parent.width)
                            height: artistLabel.height
                            hoverEnabled: true
                            enabled: bar.hasTrack && !!player.currentTrack.artistId
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!enabled) return;
                                showArtistPage(
                                    player.currentTrack.artistId,
                                    player.currentTrack.artist || "",
                                    player.currentTrack.coverArt || ""
                                )
                            }
                        }
                    }

                    Label {
                        visible: artistLabel.visible && albumWrapper.visible
                        text: qsTr("•")
                        color: theme.textSecondary
                        font.pixelSize: 13
                    }

                    Item {
                        id: albumWrapper
                        Layout.fillWidth: true
                        Layout.preferredWidth: albumLabel.implicitWidth
                        height: albumLabel.implicitHeight
                        visible: !!(player.currentTrack && player.currentTrack.album)

                        Label {
                            id: albumLabel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: player.currentTrack ? (player.currentTrack.album || "") : ""
                            color: (albumMouseArea.containsMouse && albumMouseArea.enabled) ? theme.textPrimary : theme.textSecondary
                            font.pixelSize: 13
                            elide: Label.ElideRight
                        }

                        MouseArea {
                            id: albumMouseArea
                            anchors.left: parent.left
                            anchors.verticalCenter: albumLabel.verticalCenter
                            width: Math.min(albumLabel.implicitWidth, parent.width)
                            height: albumLabel.height
                            hoverEnabled: true
                            enabled: bar.hasTrack && !!player.currentTrack.albumId
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!enabled) return;
                                showAlbumPage(
                                    player.currentTrack.albumId,
                                    player.currentTrack.album || "",
                                    player.currentTrack.artist || "",
                                    player.currentTrack.coverArt || "",
                                    player.currentTrack.artistId || ""
                                )
                            }
                        }
                    }
                }
                
                Menu {
                    id: trackContextMenu
                    width: 200
                    
                    background: Rectangle {
                        color: theme.cardBackground
                        radius: 12
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
                            font.pixelSize: 13
                            leftPadding: 16
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: menuItem.highlighted ? theme.listItemHover : "transparent"
                            radius: 8
                        }
                    }
                    
                    MenuItem {
                        text: qsTr("Go to Album")
                        enabled: bar.hasTrack && player.currentTrack.albumId
                        onTriggered: {
                            if (player.currentTrack.albumId) {
                                showAlbumPage(
                                    player.currentTrack.albumId,
                                    player.currentTrack.album || "",
                                    player.currentTrack.artist || "",
                                    player.currentTrack.coverArt || "",
                                    player.currentTrack.artistId || ""
                                )
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("Go to Artist")
                        enabled: bar.hasTrack && player.currentTrack.artistId
                        onTriggered: {
                            if (player.currentTrack.artistId) {
                                showArtistPage(
                                    player.currentTrack.artistId,
                                    player.currentTrack.artist || "",
                                    player.currentTrack.coverArt || ""
                                )
                            }
                        }
                    }
                    MenuSeparator {
                        contentItem: Rectangle {
                            implicitHeight: 1
                            color: theme.divider
                        }
                    }
                    MenuItem {
                        text: bar.hasTrack && player.currentTrack.starred ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
                        enabled: bar.hasTrack && player.currentTrack.id
                        onTriggered: {
                            if (player.currentTrack.starred) {
                                api.unstar(player.currentTrack.id)
                            } else {
                                api.star(player.currentTrack.id)
                            }
                        }
                    }
                }
            }

            // Seekbar e controles de tempo
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: player ? Utils.durationToText(player.position) : "0:00"
                    color: theme.textSecondary
                    font.pixelSize: 11
                    font.family: "monospace"
                    Layout.minimumWidth: 45
                }

                // Seekbar customizada
                Item {
                    Layout.fillWidth: true
                    height: 24
                    
                    Rectangle {
                        id: seekBarBackground
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 7
                        radius: 3.5
                        color: theme.surface
                        border.color: theme.surfaceBorder
                        border.width: 1
                        
                        Rectangle {
                            id: seekBarBuffer
                            width: parent.width * ((player && player.duration > 0) ? player.position / player.duration : 0)
                            height: parent.height
                            radius: parent.radius
                            color: theme.surfaceInteractiveBorder
                        }
                        
                        Rectangle {
                            id: seekBarProgress
                            width: parent.width * ((player && player.duration > 0) ? player.position / player.duration : 0)
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: theme.accentDark }
                                GradientStop { position: 0.5; color: theme.accent }
                                GradientStop { position: 1.0; color: theme.accentLight }
                            }
                            
                            Rectangle {
                                visible: seekMouseArea.containsMouse || seekMouseArea.pressed
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: theme.accentLight
                                border.color: theme.surface
                                border.width: 2
                            }
                        }
                    }
                    
                    MouseArea {
                        id: seekMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: player ? (player.duration > 0) : false
                        
                        onClicked: (mouse) => {
                            const pos = (mouse.x / width) * player.duration;
                            player.seek(pos);
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                const pos = (mouse.x / width) * player.duration;
                                player.seek(pos);
                            }
                        }
                    }
                    
                    // Tooltip mostrando tempo ao passar o mouse
                    Rectangle {
                        visible: seekMouseArea.containsMouse && player.duration > 0
                        x: Math.max(0, Math.min(parent.width - width, seekMouseArea.mouseX - width/2))
                        y: -30
                        width: timeTooltip.width + 12
                        height: 24
                        radius: 4
                        color: theme.surfaceInteractive
                        border.color: theme.surfaceInteractiveBorder
                        
                        Label {
                            id: timeTooltip
                            anchors.centerIn: parent
                            text: player ? Utils.durationToText((seekMouseArea.mouseX / seekMouseArea.width) * player.duration) : "0:00"
                            color: theme.textPrimary
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                    }
                }

                Label {
                    text: player ? Utils.durationToText(player.duration) : "0:00"
                    color: theme.textSecondary
                    font.pixelSize: 11
                    font.family: "monospace"
                    Layout.minimumWidth: 45
                }
            }
        }

        // Controles de reprodução
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            
            // Botão anterior
            RoundButton {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                enabled: player && bar.hasQueue
                opacity: enabled ? 1.0 : 0.4
                
                background: Rectangle {
                    radius: 20
                    color: parent.hovered ? theme.surfaceInteractive : "transparent"
                    border.color: parent.hovered ? theme.surfaceInteractiveBorder : "transparent"
                }
                
                display: AbstractButton.IconOnly
                icon.source: "../icons/skip_previous.svg"
                icon.width: 18
                icon.height: 18
                icon.color: theme.textPrimary
                
                onClicked: player.previous()
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Previous (Shift+P)")
                ToolTip.delay: 500
            }
            
            // Botão play/pause principal
            RoundButton {
                width: 52
                height: 52
                anchors.verticalCenter: parent.verticalCenter
                
                background: Rectangle {
                    radius: 26
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: parent.parent.pressed ? theme.accentDark : theme.accent }
                        GradientStop { position: 0.5; color: parent.parent.pressed ? theme.accent : theme.accentLight }
                        GradientStop { position: 1.0; color: parent.parent.pressed ? theme.accentDark : theme.accentLight }
                    }
                    
                    // Borda interna brilhante
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                }
                display: AbstractButton.IconOnly
                icon.source: (player && player.playing) ? "../icons/pause.svg" : "../icons/play_arrow.svg"
                icon.width: 22
                icon.height: 22
                icon.color: theme.textPrimary
                
                onClicked: if (player) player.toggle()
                
                ToolTip.visible: hovered
                ToolTip.text: (player && player.playing) ? "Pausar (Space)" : "Reproduzir (Space)"
                ToolTip.delay: 500
            }
            
            // Botão próxima
            RoundButton {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                enabled: player && bar.hasQueue
                opacity: enabled ? 1.0 : 0.4
                
                background: Rectangle {
                    radius: 20
                    color: parent.hovered ? theme.surfaceInteractive : "transparent"
                    border.color: parent.hovered ? theme.surfaceInteractiveBorder : "transparent"
                }
                
                display: AbstractButton.IconOnly
                icon.source: "../icons/skip_next.svg"
                icon.width: 18
                icon.height: 18
                icon.color: theme.textPrimary
                
                onClicked: player.next()
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Next (Shift+N)")
                ToolTip.delay: 500
            }
        }

        // Controles extras (volume, fila, etc)
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            
            // Controle de volume
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                
                RoundButton {
                    width: 36
                    height: 36
                    
                    background: Rectangle {
                        radius: 18
                        color: parent.hovered ? theme.surfaceInteractive : "transparent"
                        border.color: parent.hovered ? theme.surfaceInteractiveBorder : "transparent"
                    }
                    
                    display: AbstractButton.IconOnly
                    icon.source: (player && player.muted) ? "../icons/volume_off.svg" : (player && player.volume > 0.5 ? "../icons/volume_up.svg" : (player && player.volume > 0 ? "../icons/volume_down.svg" : "../icons/volume_mute.svg"))
                    icon.width: 16
                    icon.height: 16
                    icon.color: theme.textPrimary
                    
                    onClicked: if (player) player.muted = !player.muted
                    
                    ToolTip.visible: hovered
                    ToolTip.text: (player && player.muted) ? "Desmutar (M)" : "Mutar (M)"
                    ToolTip.delay: 500
                }
                
                // Slider de volume
                Item {
                    width: 100
                    height: 36
                    
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: 2.5
                        color: theme.surface
                        border.color: theme.surfaceBorder
                        border.width: 1
                        
                        Rectangle {
                            width: player ? parent.width * player.volume : 0
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: theme.accentDark }
                                GradientStop { position: 0.5; color: theme.accent }
                                GradientStop { position: 1.0; color: theme.accentLight }
                            }
                            
                            Rectangle {
                                visible: volumeMouseArea.containsMouse || volumeMouseArea.pressed
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: 12
                                radius: 6
                                color: theme.accentLight
                                border.color: theme.surface
                                border.width: 2
                            }
                        }
                    }
                    
                    MouseArea {
                        id: volumeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: (mouse) => {
                            player.volume = mouse.x / width;
                            if (player.muted) player.muted = false;
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                player.volume = Math.max(0, Math.min(1, mouse.x / width));
                                if (player.muted) player.muted = false;
                            }
                        }
                        
                        onWheel: (wheel) => {
                            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            player.volume = Math.max(0, Math.min(1, player.volume + delta));
                            if (player.muted) player.muted = false;
                        }
                    }
                    
                    // Tooltip de volume
                    Rectangle {
                        visible: volumeMouseArea.containsMouse
                        x: Math.max(0, Math.min(parent.width - width, volumeMouseArea.mouseX - width/2))
                        y: -30
                        width: volumeTooltip.width + 12
                        height: 24
                        radius: 4
                        color: theme.surfaceInteractive
                        border.color: theme.surfaceInteractiveBorder
                        
                        Label {
                            id: volumeTooltip
                            anchors.centerIn: parent
                            text: player ? (Math.round(player.volume * 100) + "%") : "0%"
                            color: theme.textPrimary
                            font.pixelSize: 11
                        }
                    }
                }
            }
            


        }
    }
}
