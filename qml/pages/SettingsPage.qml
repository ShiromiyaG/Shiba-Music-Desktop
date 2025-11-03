import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    id: settingsPage
    background: Rectangle { color: "transparent" }

    Components.ThemePalette { id: theme }

    Flickable {
        anchors.fill: parent
        anchors.margins: theme.paddingPage
        contentHeight: contentCol.height
        clip: true
        ScrollBar.vertical: Components.ScrollBar { theme.manager: themeManager }

        Column {
            id: contentCol
            width: parent.width
            spacing: theme.spacing3xl
            padding: theme.paddingPanel

            Label {
                text: qsTr("Settings")
                font.pixelSize: theme.fontSizeHero
                font.weight: Font.Bold
                color: theme.textPrimary
                font.family: theme.fontFamily
            }

            // Seção Idioma
            Rectangle {
                width: parent.width - parent.padding * 2
                height: languageSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: languageSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingXl

                    Label {
                        text: qsTr("Language")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                    }

                    Components.LanguageSelector {
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: parent.width - parent.padding * 2
                height: appearanceSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: appearanceSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingXl

                    Label {
                        text: qsTr("Appearance")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                    }

                    ComboBox {
                        id: themeCombo
                        width: parent.width
                        enabled: themeManager && themeManager.availableThemes && themeManager.availableThemes.length > 0
                        model: themeManager ? themeManager.availableThemes : []
                        textRole: "title"
                        valueRole: "id"
                        currentIndex: {
                            if (!themeManager || !themeManager.availableThemes || !themeManager.availableThemes.length)
                                return -1
                            var target = (themeManager.selectedThemeId || "").toLowerCase()
                            for (var i = 0; i < themeManager.availableThemes.length; ++i) {
                                var item = themeManager.availableThemes[i]
                                if (!item || typeof item.id !== "string")
                                    continue
                                if (item.id.toLowerCase() === target)
                                    return i
                            }
                            return themeManager.availableThemes.length > 0 ? 0 : -1
                        }
                        displayText: {
                            if (!themeManager || currentIndex < 0)
                                return ""
                            var item = themeManager.availableThemes[currentIndex]
                            return item && item.title ? item.title : ""
                        }
                        onActivated: {
                            if (!themeManager)
                                return
                            var value = currentValue || ""
                            if (value && value !== themeManager.selectedThemeId)
                                themeManager.setSelectedThemeId(value)
                        }
                        delegate: ItemDelegate {
                            width: themeCombo.width
                            highlighted: themeCombo.highlightedIndex === index
                            contentItem: Label {
                                text: modelData && modelData.title ? modelData.title : ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Label {
                        visible: themeManager ? themeManager.restartRequired : false
                        text: qsTr("Restart the application to apply the selected theme.")
                        color: theme.textSecondary
                        font.pixelSize: theme.fontSizeCaption
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            // Seção Player
            Rectangle {
                width: parent.width - parent.padding * 2
                height: playerSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: playerSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingXl

                    Label {
                        text: qsTr("Player")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("ReplayGain")
                            Layout.fillWidth: true
                            color: theme.textSecondary
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
                            color: theme.textSecondary
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
                height: discordSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: discordSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingXl

                    Label {
                        text: qsTr("Discord")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("Rich Presence")
                            Layout.fillWidth: true
                            color: theme.textSecondary
                        }
                        Switch {
                            checked: discord ? discord.enabled : false
                            onToggled: if (discord) discord.enabled = checked
                        }
                    }

                    Label {
                        text: qsTr("Shows current song in your Discord profile")
                        color: theme.textMuted
                        font.pixelSize: theme.fontSizeCaption
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("Show when paused")
                            Layout.fillWidth: true
                            color: theme.textSecondary
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
                height: serverSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: serverSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingXl

                    Label {
                        text: qsTr("Server")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }

                    RowLayout {
                        width: parent.width
                        Label {
                            text: qsTr("URL")
                            Layout.fillWidth: true
                            color: theme.textSecondary
                        }
                        Label {
                            text: api ? api.serverUrl : "" || "-"
                            color: theme.textMuted
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
                height: aboutSection.height + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder

                Column {
                    id: aboutSection
                    anchors.centerIn: parent
                    width: parent.width - theme.spacing4xl
                    spacing: theme.spacingLg

                    Label {
                        text: qsTr("About")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }

                    Label {
                        text: appInfo ? appInfo.appName : "Shiba Music"
                        font.pixelSize: theme.fontSizeTitle
                        color: theme.textPrimary
                    }

                    Label {
                        text: qsTr("Version") + " " + (appInfo ? appInfo.version : "-")
                        color: theme.textMuted
                        font.pixelSize: theme.fontSizeCaption
                    }

                    Label {
                        text: qsTr("Native Navidrome/Subsonic player in Qt")
                        color: theme.textMuted
                        font.pixelSize: theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }
}
