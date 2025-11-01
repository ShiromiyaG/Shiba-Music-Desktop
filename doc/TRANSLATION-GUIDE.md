# Guia de Tradução - Shiba Music

## Sistema de Internacionalização (i18n)

O Shiba Music agora suporta múltiplos idiomas através do sistema Qt Linguist.

## Idiomas Suportados

- 🇺🇸 **English** (en) - Padrão
- 🇧🇷 **Português** (pt)
- 🇪🇸 **Español** (es) - *Em desenvolvimento*
- 🇫🇷 **Français** (fr) - *Em desenvolvimento*
- 🇩🇪 **Deutsch** (de) - *Em desenvolvimento*
- 🇯🇵 **日本語** (ja) - *Em desenvolvimento*
- 🇨🇳 **中文** (zh) - *Em desenvolvimento*

## Como Usar no QML

### 1. Textos Simples

```qml
Label {
    text: qsTr("Home")  // Será traduzido automaticamente
}
```

### 2. Contextos

```qml
// No início do arquivo QML
pragma ComponentBehavior: Bound

// Então usar normalmente
Label {
    text: qsTr("Settings")
}
```

### 3. Componente de Seleção de Idioma

```qml
import "qrc:/qml/components" as Components

Components.LanguageSelector {
    Layout.fillWidth: true
}
```

## Como Adicionar Traduções

### Passo 1: Extrair Strings para Tradução

```bash
cd build
lupdate ../qml ../src -ts ../i18n/shibamusic_pt.ts
```

### Passo 2: Traduzir com Qt Linguist

```bash
linguist ../i18n/shibamusic_pt.ts
```

Ou edite manualmente o arquivo `.ts`:

```xml
<message>
    <source>Home</source>
    <translation>Início</translation>
</message>
```

### Passo 3: Compilar Traduções

As traduções são compiladas automaticamente durante o build do CMake.

## Adicionar Novo Idioma

### 1. Criar arquivo de tradução

```bash
cp i18n/shibamusic_en.ts i18n/shibamusic_es.ts
```

### 2. Atualizar CMakeLists.txt

```cmake
qt_add_translations(shibamusic
    TS_FILES
        i18n/shibamusic_en.ts
        i18n/shibamusic_pt.ts
        i18n/shibamusic_es.ts  # Novo idioma
    RESOURCE_PREFIX "/i18n"
)
```

### 3. Adicionar em TranslationManager.cpp

```cpp
QStringList TranslationManager::availableLanguages() const {
    return {"en", "pt", "es"};  // Adicionar "es"
}

QString TranslationManager::languageName(const QString &code) const {
    static QMap<QString, QString> names = {
        {"en", "English"},
        {"pt", "Português"},
        {"es", "Español"}  // Adicionar nome
    };
    return names.value(code, code);
}
```

## Estrutura de Arquivos

```
ShibaMusicCPP/
├── i18n/                          # Arquivos de tradução fonte (.ts)
│   ├── shibamusic_en.ts          # Inglês
│   ├── shibamusic_pt.ts          # Português
│   └── shibamusic_es.ts          # Espanhol (futuro)
│
├── src/i18n/                      # Sistema de gerenciamento
│   ├── TranslationManager.h
│   └── TranslationManager.cpp
│
└── qml/components/
    └── LanguageSelector.qml       # Componente de seleção
```

## Exemplo de Uso Completo

### SettingsPage.qml

```qml
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import "components" as Components

Page {
    title: qsTr("Settings")
    
    ScrollView {
        anchors.fill: parent
        
        ColumnLayout {
            width: parent.width
            spacing: 24
            
            // Seção de Idioma
            Rectangle {
                Layout.fillWidth: true
                height: languageSection.height + 32
                radius: 12
                color: Material.color(Material.Grey, Material.Shade900)
                
                ColumnLayout {
                    id: languageSection
                    anchors.fill: parent
                    anchors.margins: 16
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
            
            // Outras configurações...
        }
    }
}
```

## Testando

### 1. Testar Mudança de Idioma

```qml
// No console do Qt Creator ou logs
TranslationManager: Changing language to pt
TranslationManager: Loaded translation: :/i18n/shibamusic_pt.qm
```

### 2. Verificar Interface

Todos os textos com `qsTr()` devem mudar imediatamente ao trocar o idioma.

## Boas Práticas

✅ **Sempre use `qsTr()` para textos visíveis ao usuário**
```qml
text: qsTr("Connect")  // ✅ Correto
```

❌ **Não coloque textos diretos**
```qml
text: "Connect"  // ❌ Não será traduzido
```

✅ **Use contextos descritivos**
```qml
// NavigationMenu.qml
Label { text: qsTr("Home") }

// SettingsPage.qml  
Label { text: qsTr("Home") }
// Ambos compartilham a mesma tradução
```

✅ **Mantenha variáveis fora das traduções**
```qml
text: qsTr("Version") + " " + appInfo.version  // ✅ Correto
```

## Compilação

O sistema compila automaticamente durante o build:

```bash
cmake --build build --config Release
```

Os arquivos `.qm` compilados são embutidos no executável via recursos Qt.

## Detecção Automática

O idioma é detectado automaticamente na primeira execução:
1. Verifica se há idioma salvo nas configurações
2. Se não, usa o idioma do sistema operacional
3. Se o idioma do sistema não estiver disponível, usa inglês

A preferência é salva em:
- Windows: `HKEY_CURRENT_USER\Software\ShibaMusic\ShibaMusic`
- Linux/Mac: `~/.config/ShibaMusic/ShibaMusic.conf`

## Contribuindo com Traduções

Para contribuir com traduções:

1. Fork o repositório
2. Crie/edite o arquivo `i18n/shibamusic_XX.ts` (XX = código do idioma)
3. Traduza as strings no arquivo .ts
4. Faça um Pull Request

Traduções são muito bem-vindas! 🌍
