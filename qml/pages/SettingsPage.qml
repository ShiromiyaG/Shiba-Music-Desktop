import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

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
                text: qsTr("Settings")
                font.pixelSize: 32
                font.weight: Font.Bold
            }

            // Seção Idioma
            Rectangle {
                width: parent.width - parent.padding * 2
                height: languageSection.height + 32
                radius: 16
                color: "#1b2336"
                border.color: "#252e42"

                Column {
                    id: languageSection
                    anchors.centerIn: parent
                    width: parent.width - 32
                    spacing: 16

                    Label {
                        text: qsTr("Language")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Components.LanguageSelector {
                        width: parent.width
                    }
                }
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
                        text: qsTr("Player")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("ReplayGain")
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: player ? player.replayGainEnabled : false
                            onCheckedChanged: if (player) player.replayGainEnabled = checked
                        }
                    }

                    RowLayout {
                        width: parent.width
                        visible: player ? player.replayGainEnabled : false
                        Label {
                            text: qsTr("ReplayGain Mode")
                            Layout.fillWidth: true
                        }
                        ComboBox {
                            model: ["Track", "Album"]
                            currentIndex: player ? player.replayGainMode : 0
                            onActivated: if (player) player.replayGainMode = currentIndex
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
                        text: qsTr("Discord")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("Rich Presence")
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: discord ? discord.enabled : false
                            onToggled: if (discord) discord.enabled = checked
                        }
                    }

                    Label {
                        text: qsTr("Shows current song in your Discord profile")
                        color: "#8b96a8"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("Show when paused")
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: discord ? discord.showPaused : false
                            onToggled: if (discord) discord.showPaused = checked
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
                        text: qsTr("Server")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("URL")
                            Layout.fillWidth: true
                        }
                        Label {
                            text: api ? api.serverUrl : "" || "-"
                            color: "#8b96a8"
                            elide: Label.ElideRight
                            Layout.maximumWidth: 300
                        }
                    }

                    Button {
                        text: qsTr("Disconnect")
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
                        text: qsTr("About")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: appInfo ? appInfo.appName : "Shiba Music"
                        font.pixelSize: 16
                    }

                    Label {
                        text: qsTr("Version") + " " + (appInfo ? appInfo.version : "-")
                        color: "#8b96a8"
                        font.pixelSize: 12
                    }

                    Label {
                        text: qsTr("Native Navidrome/Subsonic player in Qt")
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


