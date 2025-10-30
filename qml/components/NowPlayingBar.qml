import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "qrc:/qml/js/utils.js" as Utils

Rectangle {
    id: bar
    width: parent ? parent.width : 800
    height: 110
    
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#161b22" }
        GradientStop { position: 1.0; color: "#0d1117" }
    }
    signal queueRequested()
    readonly property bool hasQueue: !!player.queue && player.queue.length > 0
    readonly property bool hasTrack: !!(player.currentTrack && player.currentTrack.id)

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
                radius: 14
                color: "#0d1117"
                border.color: "#21262d"
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

                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: player.playing ? 0.1 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
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

                // Overlay de play/pause
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: coverMouseArea.containsMouse ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    
                    Image {
                        anchors.centerIn: parent
                        source: player.playing ? "../icons/pause.svg" : "../icons/play_arrow.svg"
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
                    onClicked: player.toggle()
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
                    color: bar.hasTrack ? "#f0f6fc" : "#8b949e"
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Label {
                        Layout.fillWidth: true
                        text: bar.hasTrack ? player.currentTrack.artist : "Selecione uma música para começar"
                        color: "#8b949e"
                        font.pixelSize: 13
                        elide: Label.ElideRight
                    }
                    
                    Label {
                        visible: bar.hasTrack && player.currentTrack.album
                        text: bar.hasTrack ? ("• " + player.currentTrack.album) : ""
                        color: "#6e7681"
                        font.pixelSize: 12
                        elide: Label.ElideRight
                        Layout.maximumWidth: 200
                    }
                }
            }

            // Seekbar e controles de tempo
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: Utils.durationToText(player.position)
                    color: "#8b949e"
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
                        color: "#161b22"
                        border.color: "#21262d"
                        border.width: 1
                        
                        Rectangle {
                            id: seekBarBuffer
                            width: parent.width * (player.duration > 0 ? player.position / player.duration : 0)
                            height: parent.height
                            radius: parent.radius
                            color: "#30363d"
                        }
                        
                        Rectangle {
                            id: seekBarProgress
                            width: parent.width * (player.duration > 0 ? player.position / player.duration : 0)
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#0969da" }
                                GradientStop { position: 0.5; color: "#1f6feb" }
                                GradientStop { position: 1.0; color: "#58a6ff" }
                            }
                            
                            Rectangle {
                                visible: seekMouseArea.containsMouse || seekMouseArea.pressed
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: "#58a6ff"
                                border.color: "#0d1117"
                                border.width: 2
                            }
                        }
                    }
                    
                    MouseArea {
                        id: seekMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: player.duration > 0
                        
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
                        color: "#1f2937"
                        border.color: "#374151"
                        
                        Label {
                            id: timeTooltip
                            anchors.centerIn: parent
                            text: Utils.durationToText((seekMouseArea.mouseX / seekMouseArea.width) * player.duration)
                            color: "#e6edf3"
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                    }
                }

                Label {
                    text: Utils.durationToText(player.duration)
                    color: "#8b949e"
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
                enabled: bar.hasQueue
                opacity: enabled ? 1.0 : 0.4
                
                background: Rectangle {
                    radius: 20
                    color: parent.hovered ? "#1f2937" : "transparent"
                    border.color: parent.hovered ? "#374151" : "transparent"
                }
                
                contentItem: Image {
                    source: "../icons/skip_previous.svg"
                    width: 18
                    height: 18
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }
                
                ToolTip.visible: hovered
                ToolTip.text: "Anterior (Shift+P)"
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
                        GradientStop { position: 0.0; color: parent.parent.pressed ? "#0969da" : "#1f6feb" }
                        GradientStop { position: 0.5; color: parent.parent.pressed ? "#1f6feb" : "#388bfd" }
                        GradientStop { position: 1.0; color: parent.parent.pressed ? "#0969da" : "#58a6ff" }
                    }
                    
                    // Borda interna brilhante
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                }
                contentItem: Image {
                    source: player.playing ? "../icons/pause.svg" : "../icons/play_arrow.svg"
                    width: 22
                    height: 22
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }
                
                onClicked: player.toggle()
                
                ToolTip.visible: hovered
                ToolTip.text: player.playing ? "Pausar (Space)" : "Reproduzir (Space)"
                ToolTip.delay: 500
            }
            
            // Botão próxima
            RoundButton {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                enabled: bar.hasQueue
                opacity: enabled ? 1.0 : 0.4
                
                background: Rectangle {
                    radius: 20
                    color: parent.hovered ? "#1f2937" : "transparent"
                    border.color: parent.hovered ? "#374151" : "transparent"
                }
                
                contentItem: Image {
                    source: "../icons/skip_next.svg"
                    width: 18
                    height: 18
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }
                
                onClicked: player.next()
                
                ToolTip.visible: hovered
                ToolTip.text: "Próxima (Shift+N)"
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
                        color: parent.hovered ? "#1f2937" : "transparent"
                        border.color: parent.hovered ? "#374151" : "transparent"
                    }
                    
                    contentItem: Image {
                        source: player.muted ? "../icons/volume_off.svg" : (player.volume > 0.5 ? "../icons/volume_up.svg" : (player.volume > 0 ? "../icons/volume_down.svg" : "../icons/volume_mute.svg"))
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    onClicked: player.muted = !player.muted
                    
                    ToolTip.visible: hovered
                    ToolTip.text: player.muted ? "Desmutar (M)" : "Mutar (M)"
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
                        color: "#161b22"
                        border.color: "#21262d"
                        border.width: 1
                        
                        Rectangle {
                            width: parent.width * player.volume
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#0969da" }
                                GradientStop { position: 0.5; color: "#1f6feb" }
                                GradientStop { position: 1.0; color: "#58a6ff" }
                            }
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#1f6feb"
                                shadowBlur: 0.3
                                shadowOpacity: 0.6
                            }
                            
                            Rectangle {
                                visible: volumeMouseArea.containsMouse || volumeMouseArea.pressed
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: 12
                                radius: 6
                                color: "#58a6ff"
                                border.color: "#0d1117"
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
                        color: "#1f2937"
                        border.color: "#374151"
                        
                        Label {
                            id: volumeTooltip
                            anchors.centerIn: parent
                            text: Math.round(player.volume * 100) + "%"
                            color: "#e6edf3"
                            font.pixelSize: 11
                        }
                    }
                }
            }
            
            // Separador
            Rectangle {
                width: 1
                height: 32
                color: "#21262d"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // Crossfade
            RoundButton {
                width: 36
                height: 36
                checkable: true
                checked: player ? player.crossfade : false
                
                background: Rectangle {
                    radius: 18
                    color: parent.checked ? "#1f6feb" : (parent.hovered ? "#1f2937" : "transparent")
                    border.color: parent.checked ? "#58a6ff" : (parent.hovered ? "#374151" : "transparent")
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                contentItem: Image {
                    source: "../icons/auto_awesome.svg"
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    opacity: parent.checked ? 1.0 : 0.5
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                onToggled: player.crossfade = checked
                
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Crossfade ativado" : "Crossfade desativado"
                ToolTip.delay: 500
            }
            
            // Fila
            RoundButton {
                width: 36
                height: 36
                
                background: Rectangle {
                    radius: 18
                    color: parent.hovered ? "#1f2937" : "transparent"
                    border.color: parent.hovered ? "#374151" : "transparent"
                }
                
                contentItem: Image {
                    source: "../icons/queue_music.svg"
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }
                
                onClicked: bar.queueRequested()
                
                ToolTip.visible: hovered
                ToolTip.text: "Abrir fila (Q)"
                ToolTip.delay: 500
                
                // Badge com número de músicas
                Rectangle {
                    visible: bar.hasQueue && player.queue.length > 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    width: Math.max(16, badgeText.width + 6)
                    height: 16
                    radius: 8
                    color: "#1f6feb"
                    border.color: "#0d1117"
                    border.width: 1
                    
                    Label {
                        id: badgeText
                        anchors.centerIn: parent
                        text: player.queue.length
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
