# Exemplo: Convertendo Textos Existentes para Sistema i18n

## Antes (main.qml - linhas atuais)

```qml
property var navigationItems: [
    { label: "Início", icon: "qrc:/qml/icons/home.svg", target: "home" },
    { label: "Playlists", icon: "qrc:/qml/icons/queue_music.svg", target: "playlists" },
    { label: "Favoritos", icon: "qrc:/qml/icons/star.svg", target: "favorites" },
    { label: "Álbuns", icon: "qrc:/qml/icons/album.svg", target: "albums" },
    { label: "Artistas", icon: "qrc:/qml/icons/mic.svg", target: "artists" },
    { label: "Configurações", icon: "qrc:/qml/icons/settings.svg", target: "settings" }
]
```

## Depois (com i18n)

```qml
property var navigationItems: [
    { label: qsTr("Home"), icon: "qrc:/qml/icons/home.svg", target: "home" },
    { label: qsTr("Playlists"), icon: "qrc:/qml/icons/queue_music.svg", target: "playlists" },
    { label: qsTr("Favorites"), icon: "qrc:/qml/icons/star.svg", target: "favorites" },
    { label: qsTr("Albums"), icon: "qrc:/qml/icons/album.svg", target: "albums" },
    { label: qsTr("Artists"), icon: "qrc:/qml/icons/mic.svg", target: "artists" },
    { label: qsTr("Settings"), icon: "qrc:/qml/icons/settings.svg", target: "settings" }
]
```

## LoginPage.qml

### Antes
```qml
Label {
    text: "Bem-vindo ao Shiba Music"
}

TextField {
    placeholderText: "URL do Servidor"
}

TextField {
    placeholderText: "Usuário"
}

TextField {
    placeholderText: "Senha"
}

Button {
    text: api.authenticating ? "Conectando..." : "Conectar"
}
```

### Depois
```qml
Label {
    text: qsTr("Welcome to Shiba Music")
}

TextField {
    placeholderText: qsTr("Server URL")
}

TextField {
    placeholderText: qsTr("Username")
}

TextField {
    placeholderText: qsTr("Password")
}

Button {
    text: api.authenticating ? qsTr("Connecting...") : qsTr("Connect")
}
```

## UpdateDialog.qml

### Antes
```qml
Dialog {
    title: "Update Available"
    
    Label {
        text: "New Version Available"
    }
    
    Label {
        text: "Version " + updateChecker.latestVersion
    }
    
    Button {
        text: "Later"
    }
    
    Button {
        text: updateChecker.isDownloading ? "Downloading..." : "Download & Install"
    }
}
```

### Depois
```qml
Dialog {
    title: qsTr("Update Available")
    
    Label {
        text: qsTr("New Version Available")
    }
    
    Label {
        text: qsTr("Version") + " " + updateChecker.latestVersion
    }
    
    Button {
        text: qsTr("Later")
    }
    
    Button {
        text: updateChecker.isDownloading ? qsTr("Downloading...") : qsTr("Download & Install")
    }
}
```

## SettingsPage.qml (Novo)

```qml
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import "qrc:/qml/components" as Components

Page {
    title: qsTr("Settings")
    
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        
        ColumnLayout {
            width: parent.width
            spacing: 24
            padding: 24
            
            // Language Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: languageContent.height + 32
                radius: 16
                color: Material.color(Material.Grey, Material.Shade900)
                
                ColumnLayout {
                    id: languageContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 16
                    
                    Label {
                        text: qsTr("Language")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    
                    Components.LanguageSelector {
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Discord Integration Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: discordContent.height + 32
                radius: 16
                color: Material.color(Material.Grey, Material.Shade900)
                
                ColumnLayout {
                    id: discordContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 16
                    
                    Label {
                        text: qsTr("Discord Integration")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    
                    Switch {
                        text: qsTr("Show Discord Rich Presence")
                        checked: discord.enabled
                        onToggled: discord.setEnabled(checked)
                    }
                }
            }
            
            // About Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: aboutContent.height + 32
                radius: 16
                color: Material.color(Material.Grey, Material.Shade900)
                
                ColumnLayout {
                    id: aboutContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 8
                    
                    Label {
                        text: qsTr("About")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    
                    Label {
                        text: qsTr("Version") + " " + appInfo.version
                        opacity: 0.7
                    }
                }
            }
            
            // Logout Button
            Button {
                Layout.fillWidth: true
                text: qsTr("Logout")
                Material.background: Material.Red
                onClicked: api.logout()
            }
        }
    }
}
```

## Script de Conversão Rápida

Para converter textos existentes automaticamente (exemplo):

```powershell
# Substituir textos comuns em todos os arquivos QML
Get-ChildItem -Path qml -Filter "*.qml" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Substituições comuns
    $content = $content -replace '"Início"', 'qsTr("Home")'
    $content = $content -replace '"Playlists"', 'qsTr("Playlists")'
    $content = $content -replace '"Favoritos"', 'qsTr("Favorites")'
    $content = $content -replace '"Álbuns"', 'qsTr("Albums")'
    $content = $content -replace '"Artistas"', 'qsTr("Artists")'
    $content = $content -replace '"Configurações"', 'qsTr("Settings")'
    
    Set-Content $_.FullName -Value $content
}
```

## Checklist de Conversão

- [ ] Identificar todos os textos visíveis ao usuário
- [ ] Substituir por `qsTr("texto_em_ingles")`
- [ ] Atualizar arquivo `.ts` com lupdate
- [ ] Adicionar traduções no Qt Linguist
- [ ] Compilar e testar
- [ ] Verificar mudança de idioma em tempo real

## Teste Rápido

1. Compilar o projeto
2. Executar o app
3. Ir em Settings
4. Mudar o idioma
5. Verificar se todos os textos mudam imediatamente
