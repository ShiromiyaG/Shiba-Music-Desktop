# 🌍 Sistema de Internacionalização do Shiba Music

## ✅ O que foi implementado

### 1. **TranslationManager** (C++)
Gerencia todas as traduções da aplicação:
- Detecta idioma do sistema automaticamente
- Salva preferência do usuário
- Troca idioma em tempo real
- Suporta 7 idiomas

### 2. **Arquivos de Tradução** (.ts)
- ✅ `i18n/shibamusic_en.ts` - Inglês (base)
- ✅ `i18n/shibamusic_pt.ts` - Português BR (completo)
- 🔄 `i18n/shibamusic_es.ts` - Espanhol (futuro)
- 🔄 `i18n/shibamusic_fr.ts` - Francês (futuro)
- 🔄 `i18n/shibamusic_de.ts` - Alemão (futuro)
- 🔄 `i18n/shibamusic_ja.ts` - Japonês (futuro)
- 🔄 `i18n/shibamusic_zh.ts` - Chinês (futuro)

### 3. **LanguageSelector** (QML)
Componente para seleção de idioma:
```qml
import "qrc:/qml/components" as Components

Components.LanguageSelector {
    Layout.fillWidth: true
}
```

### 4. **Integração CMake**
Build automático de traduções:
```cmake
qt_add_translations(shibamusic
    TS_FILES i18n/shibamusic_*.ts
    RESOURCE_PREFIX "/i18n"
)
```

## 📁 Estrutura de Arquivos

```
ShibaMusicCPP/
├── src/
│   ├── main.cpp                        # Inicializa TranslationManager
│   └── i18n/
│       ├── TranslationManager.h        # Gerenciador de traduções
│       └── TranslationManager.cpp
│
├── i18n/
│   ├── shibamusic_en.ts               # Traduções em inglês
│   ├── shibamusic_pt.ts               # Traduções em português
│   └── ... (outros idiomas)
│
├── qml/
│   └── components/
│       └── LanguageSelector.qml       # Seletor de idioma
│
├── CMakeLists.txt                     # Build configurado
├── TRANSLATION-GUIDE.md               # Guia completo
├── EXAMPLE-TRANSLATION.md             # Exemplos práticos
└── I18N-README.md                     # Este arquivo
```

## 🚀 Como Usar

### Em QML (Interface)

**Antes:**
```qml
Label {
    text: "Configurações"
}
```

**Depois:**
```qml
Label {
    text: qsTr("Settings")  // Traduzido automaticamente!
}
```

### No código C++ (se necessário)

```cpp
QString text = tr("Settings");
```

## 🔄 Fluxo de Tradução

```
1. Desenvolvedor marca textos com qsTr()
   ↓
2. lupdate extrai strings para arquivos .ts
   ↓
3. Tradutor traduz no Qt Linguist ou editor
   ↓
4. CMake compila .ts → .qm automaticamente
   ↓
5. Arquivos .qm são incluídos no executável
   ↓
6. TranslationManager carrega tradução em runtime
   ↓
7. Interface atualiza instantaneamente!
```

## 📝 Passo a Passo: Adicionar Tradução

### Passo 1: Marcar Textos
```qml
// Antes
text: "Conectar"

// Depois  
text: qsTr("Connect")
```

### Passo 2: Extrair Strings
```bash
cd build
lupdate ../qml ../src -ts ../i18n/shibamusic_pt.ts
```

### Passo 3: Traduzir
Edite `i18n/shibamusic_pt.ts`:
```xml
<message>
    <source>Connect</source>
    <translation>Conectar</translation>
</message>
```

### Passo 4: Compilar
```bash
cmake --build . --config Release
```

Pronto! 🎉

## 🌐 Idiomas Suportados

| Código | Idioma    | Status | Nome Nativo |
|--------|-----------|--------|-------------|
| `en`   | Inglês    | ✅ Base | English     |
| `pt`   | Português | ✅ OK   | Português   |
| `es`   | Espanhol  | 🔄 TODO | Español     |
| `fr`   | Francês   | 🔄 TODO | Français    |
| `de`   | Alemão    | 🔄 TODO | Deutsch     |
| `ja`   | Japonês   | 🔄 TODO | 日本語      |
| `zh`   | Chinês    | 🔄 TODO | 中文        |

## 🎯 Exemplos de Uso

### Navegação Principal
```qml
property var navigationItems: [
    { label: qsTr("Home"), icon: "home.svg" },
    { label: qsTr("Playlists"), icon: "playlist.svg" },
    { label: qsTr("Favorites"), icon: "star.svg" },
    { label: qsTr("Albums"), icon: "album.svg" },
    { label: qsTr("Artists"), icon: "mic.svg" },
    { label: qsTr("Settings"), icon: "settings.svg" }
]
```

### Página de Login
```qml
Page {
    title: qsTr("Login")
    
    TextField {
        placeholderText: qsTr("Server URL")
    }
    
    Button {
        text: qsTr("Connect")
    }
}
```

### Diálogo de Atualização
```qml
Dialog {
    title: qsTr("Update Available")
    
    Label {
        text: qsTr("New Version Available")
    }
    
    Button {
        text: qsTr("Download & Install")
    }
}
```

## ⚙️ Configuração do Usuário

O idioma selecionado é salvo automaticamente em:

**Windows:**
```
HKEY_CURRENT_USER\Software\ShibaMusic\ShibaMusic
→ language = "pt"
```

**Linux/Mac:**
```
~/.config/ShibaMusic/ShibaMusic.conf
→ language=pt
```

## 🔍 Detecção Automática

Na primeira execução:
1. Verifica configuração salva
2. Se não houver → detecta idioma do sistema
3. Se idioma não suportado → usa inglês
4. Salva preferência

## 📚 Documentação Completa

- **TRANSLATION-GUIDE.md** - Guia detalhado para desenvolvedores
- **EXAMPLE-TRANSLATION.md** - Exemplos práticos de conversão
- **I18N-README.md** - Esta visão geral

## 🤝 Como Contribuir

### Adicionar Novo Idioma

1. Copiar arquivo base:
```bash
cp i18n/shibamusic_en.ts i18n/shibamusic_XX.ts
```

2. Atualizar `CMakeLists.txt`:
```cmake
qt_add_translations(shibamusic
    TS_FILES
        i18n/shibamusic_en.ts
        i18n/shibamusic_pt.ts
        i18n/shibamusic_XX.ts  # Adicionar aqui
)
```

3. Atualizar `TranslationManager.cpp`:
```cpp
QStringList availableLanguages() const {
    return {"en", "pt", "XX"};  // Adicionar código
}

QString languageName(const QString &code) const {
    return {
        {"XX", "Nome Nativo"}  // Adicionar nome
    };
}
```

4. Traduzir arquivo `.ts`

5. Pull Request! 🎉

## 🐛 Troubleshooting

### Tradução não aparece
- Verificar se o texto está marcado com `qsTr()`
- Recompilar o projeto
- Verificar se o arquivo `.qm` foi gerado em `build/`

### Idioma não muda
- Verificar logs no console
- Confirmar que TranslationManager está inicializado
- Verificar permissões de escrita no registry/config

### Novo texto não traduz
- Executar `lupdate` para extrair novas strings
- Adicionar traduções no arquivo `.ts`
- Recompilar

## ✨ Benefícios

- ✅ Interface totalmente localizável
- ✅ Mudança de idioma em tempo real
- ✅ Sem necessidade de reiniciar
- ✅ Detecção automática do sistema
- ✅ Fácil de adicionar novos idiomas
- ✅ Integrado com Qt Linguist
- ✅ Build automático

## 🎨 Preview

```
┌─────────────────────────────────────┐
│  🎵 Shiba Music                     │
├─────────────────────────────────────┤
│  🏠 Home          (Início)          │
│  📋 Playlists     (Playlists)       │
│  ⭐ Favorites     (Favoritos)       │
│  💿 Albums        (Álbuns)          │
│  🎤 Artists       (Artistas)        │
│  ⚙️  Settings     (Configurações)   │
└─────────────────────────────────────┘
```

---

**Status:** ✅ Sistema completo e funcional
**Próximo passo:** Converter textos existentes e adicionar mais idiomas
