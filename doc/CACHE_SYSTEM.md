# Sistema de Cache - Shiba Music

## Visão Geral

O Shiba Music agora possui um sistema robusto de cache baseado em SQLite que armazena:
- **Imagens** (capas de álbuns, fotos de artistas)
- **Metadados** (informações de álbuns, artistas, faixas)
- **Listas** (lista de artistas, álbuns, playlists)

## Arquitetura

### Banco de Dados
- **Localização**: `%LOCALAPPDATA%/ShibaMusic/shibamusic_cache.db`
- **Engine**: SQLite3
- **Tabelas**:
  - `image_cache` - Armazena imagens em formato JPEG
  - `metadata_cache` - Armazena metadados JSON
  - `list_cache` - Armazena listas completas

### Classe CacheManager

```cpp
class CacheManager : public QObject {
    // Image cache
    Q_INVOKABLE bool hasImage(const QString& url);
    Q_INVOKABLE QPixmap getImage(const QString& url);
    Q_INVOKABLE void saveImage(const QString& url, const QPixmap& pixmap);
    
    // Metadata cache
    Q_INVOKABLE bool hasMetadata(const QString& type, const QString& id);
    Q_INVOKABLE QVariantMap getMetadata(const QString& type, const QString& id);
    Q_INVOKABLE void saveMetadata(const QString& type, const QString& id, const QVariantMap& data);
    
    // List cache
    Q_INVOKABLE bool hasList(const QString& type);
    Q_INVOKABLE QVariantList getList(const QString& type);
    Q_INVOKABLE void saveList(const QString& type, const QVariantList& data);
    
    // Management
    Q_INVOKABLE qint64 getCacheSize();
    Q_INVOKABLE int getImageCount();
    Q_INVOKABLE void clearAllCache();
};
```

## Como Usar

### 1. Cache de Imagens

```qml
// Verificar se imagem está em cache
if (cacheManager.hasImage(coverUrl)) {
    coverImage.source = coverUrl
} else {
    // Baixar e cachear
    image.onStatusChanged: {
        if (image.status === Image.Ready) {
            cacheManager.saveImage(coverUrl, image)
        }
    }
}
```

### 2. Cache de Metadados

```qml
// Ao buscar álbum
function fetchAlbum(albumId) {
    if (cacheManager.hasMetadata("album", albumId)) {
        var album = cacheManager.getMetadata("album", albumId)
        displayAlbum(album)
    } else {
        api.fetchAlbum(albumId)
        // Após receber do servidor:
        cacheManager.saveMetadata("album", albumId, albumData)
    }
}
```

### 3. Cache de Listas

```qml
// Ao buscar lista de artistas
function fetchArtists() {
    if (cacheManager.hasList("artists")) {
        var artists = cacheManager.getList("artists")
        displayArtists(artists)
    }
    
    // Atualizar do servidor
    api.fetchArtists()
    // Após receber:
    cacheManager.saveList("artists", artistsData)
}
```

## Gerenciamento de Cache

### Configurações Disponíveis

1. **Limpar Imagens Antigas (30+ dias)**
   ```cpp
   cacheManager.clearImageCache(30);
   ```

2. **Limpar Metadados Antigos (7+ dias)**
   ```cpp
   cacheManager.clearMetadataCache(7);
   ```

3. **Limpar Cache de Listas**
   ```cpp
   cacheManager.clearListCache();
   ```

4. **Limpar Todo Cache**
   ```cpp
   cacheManager.clearAllCache();
   ```

### Interface de Configurações

Uma página dedicada `CacheSettingsPage.qml` permite ao usuário:
- Ver estatísticas do cache (tamanho, quantidade de imagens)
- Limpar caches seletivamente
- Limpar todo o cache

## Benefícios

### Performance
- ⚡ **Carregamento instantâneo** de conteúdo já visualizado
- 🚀 **Redução de requisições** ao servidor Subsonic
- 📶 **Modo offline parcial** - conteúdo cacheado disponível sem conexão

### Experiência do Usuário
- 🖼️ **Imagens aparecem imediatamente**
- 📋 **Listas carregam instantaneamente**
- 💾 **Menos consumo de dados**

### Técnicas
- 🗜️ **Compressão JPEG** com qualidade 90 para imagens
- 📊 **Índices SQL** para buscas rápidas
- ⏱️ **Timestamps** para invalidação automática
- 🧹 **Limpeza automática** de dados antigos

## Implementação Futura

### Sugestões de Melhorias

1. **Cache Inteligente**
   - Pré-carregar álbuns relacionados
   - Cache preditivo baseado em histórico

2. **Sincronização**
   - Sincronizar cache entre dispositivos
   - Backup na nuvem

3. **Otimizações**
   - Compressão de metadados
   - Cache em memória (LRU) para acesso ultra-rápido
   - WebP para imagens (melhor compressão)

4. **Configurações Avançadas**
   - Tamanho máximo do cache
   - Qualidade de compressão personalizável
   - Política de expiração configurável

## Exemplo de Integração Completa

```qml
// Em HomePage.qml
Component.onCompleted: {
    // Tentar carregar do cache primeiro
    if (cacheManager.hasList("recentAlbums")) {
        recentAlbums = cacheManager.getList("recentAlbums")
    }
    
    // Buscar atualizações do servidor
    api.fetchRecentAlbums()
}

Connections {
    target: api
    function onRecentAlbumsChanged() {
        // Atualizar cache com novos dados
        cacheManager.saveList("recentAlbums", api.recentAlbums)
        recentAlbums = api.recentAlbums
    }
}
```

## Troubleshooting

### Cache não está funcionando
1. Verificar se o banco de dados foi inicializado: `cacheManager.initialize()`
2. Verificar permissões de escrita em `%LOCALAPPDATA%/ShibaMusic/`
3. Ver logs no console para erros SQL

### Cache muito grande
1. Usar a página de configurações para limpar caches antigos
2. Ajustar políticas de expiração
3. Limpar cache completo e reconstruir

### Dados desatualizados
1. Usar `clearListCache()` para forçar atualização de listas
2. Implementar lógica de TTL (Time To Live) no código

## API Reference

Ver documentação completa em:
- `src/core/CacheManager.h` - Interface completa
- `src/core/CacheManager.cpp` - Implementação
- `qml/pages/CacheSettingsPage.qml` - Interface de gerenciamento
