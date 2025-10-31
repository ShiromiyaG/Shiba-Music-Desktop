import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: settingsPage
    background: Rectangle { color: "transparent" }

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.height
        clip: true
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: contentCol
            width: parent.width
            spacing: 24
            padding: 24

            Label {
                text: "Configurações"
                font.pixelSize: 32
                font.weight: Font.Bold
            }

            // Seção Player
            Rectangle {
                width: parent.width - parent.padding * 2
                height: playerSection.height + 32
                radius: 16
                color: "#1b2336"
                border.color: "#252e42"

                Column {
                    id: playerSection
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 16

                    Label {
                        text: "Player"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "Crossfade"
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: player.crossfade
                            onToggled: player.crossfade = checked
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "ReplayGain"
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: player.replayGainEnabled
                            onCheckedChanged: player.replayGainEnabled = checked
                        }
                    }

                    RowLayout {
                        width: parent.width
                        visible: player.replayGainEnabled
                        Label {
                            text: "Modo ReplayGain"
                            Layout.fillWidth: true
                        }
                        ComboBox {
                            model: ["Track", "Album"]
                            currentIndex: player.replayGainMode
                            onActivated: player.replayGainMode = currentIndex
                        }
                    }
                }
            }

            // Seção Discord
            Rectangle {
                width: parent.width - parent.padding * 2
                height: discordSection.height + 32
                radius: 16
                color: "#1b2336"
                border.color: "#252e42"

                Column {
                    id: discordSection
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 16

                    Label {
                        text: "Discord"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "Rich Presence"
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: discord.enabled
                            onToggled: discord.enabled = checked
                        }
                    }

                    Label {
                        text: "Exibe a música atual no seu perfil do Discord"
                        color: "#8b96a8"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "Mostrar quando pausado"
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: discord.showPaused
                            onToggled: discord.showPaused = checked
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "Application ID"
                            Layout.fillWidth: true
                        }
                        TextField {
                            text: discord.clientId
                            placeholderText: "Digite seu Application ID"
                            Layout.preferredWidth: 200
                            onEditingFinished: discord.clientId = text
                        }
                    }
                }
            }

            // Seção Servidor
            Rectangle {
                width: parent.width - parent.padding * 2
                height: serverSection.height + 32
                radius: 16
                color: "#1b2336"
                border.color: "#252e42"

                Column {
                    id: serverSection
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 16

                    Label {
                        text: "Servidor"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: "URL"
                            Layout.fillWidth: true
                        }
                        Label {
                            text: api.serverUrl || "-"
                            color: "#8b96a8"
                            elide: Label.ElideRight
                            Layout.maximumWidth: 300
                        }
                    }

                    Button {
                        text: "Desconectar"
                        onClicked: {
                            api.logout()
                        }
                    }
                }
            }

            // Seção Sobre
            Rectangle {
                width: parent.width - parent.padding * 2
                height: aboutSection.height + 32
                radius: 16
                color: "#1b2336"
                border.color: "#252e42"

                Column {
                    id: aboutSection
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 12

                    Label {
                        text: "Sobre"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "Shiba Music"
                        font.pixelSize: 16
                    }

                    Label {
                        text: "Player Navidrome/Subsonic nativo em Qt"
                        color: "#8b96a8"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }
}
