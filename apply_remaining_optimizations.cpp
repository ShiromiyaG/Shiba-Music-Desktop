// INSTRUÇÕES: Aplicar manualmente estas otimizações adicionais

// ============================================
// 1. String Pooling em fetchArtists()
// ============================================
// Localizar em SubsonicClient.cpp, linha ~1050:
/*
for (const auto &aVal : idx.value("artist").toArray()) {
    auto a = aVal.toObject();
    QVariantMap m {
        {"id", internString(a.value("id").toString())},  // ADICIONAR internString
        {"name", a.value("name").toString()},
        {"coverArt", internString(a.value("coverArt").toString())}  // ADICIONAR internString
    };
    m_artists.push_back(m);
}
*/

// ============================================
// 2. String Pooling em fetchAlbum()
// ============================================
// Localizar em SubsonicClient.cpp, linha ~1200:
/*
TrackEntry entry;
entry.id = internString(s.value("id").toString());  // ADICIONAR internString
entry.title = s.value("title").toString();
entry.artist = internString(s.value("artist").toString());  // ADICIONAR internString
entry.artistId = internString(s.value("artistId").toString());  // ADICIONAR internString
entry.album = internString(s.value("album").toString());  // ADICIONAR internString
entry.albumId = internString(s.value("albumId").toString());  // ADICIONAR internString
entry.coverArt = internString(s.value("coverArt").toString());  // ADICIONAR internString
*/

// ============================================
// 3. Limpeza Automática de Busca
// ============================================
// Adicionar no final de search() em SubsonicClient.cpp:
/*
QTimer::singleShot(120000, this, [this]() {
    if (!m_searchArtists.isEmpty()) {
        m_searchArtists.clear();
        m_searchArtists.squeeze();
        emit searchArtistsChanged();
    }
    if (!m_searchAlbums.isEmpty()) {
        m_searchAlbums.clear();
        m_searchAlbums.squeeze();
        emit searchAlbumsChanged();
    }
});
*/

// ============================================
// 4. Otimização SQLite em CacheManager.cpp
// ============================================
// Adicionar em createTables():
/*
query.exec("PRAGMA page_size = 4096");
query.exec("PRAGMA auto_vacuum = INCREMENTAL");
query.exec("PRAGMA journal_mode = WAL");
query.exec("PRAGMA synchronous = NORMAL");
query.exec("PRAGMA temp_store = MEMORY");
*/

// ============================================
// 5. Limitar Tamanho do String Pool
// ============================================
// Adicionar em SubsonicClient.cpp após internString():
/*
static void cleanStringPool() {
    if (g_stringPool.size() > 1000) {
        g_stringPool.clear();
    }
}
// Chamar em logout():
cleanStringPool();
*/

// ============================================
// 6. Reduzir Cache de Imagens em Disco
// ============================================
// Em CacheManager.cpp, clearImageCache():
/*
void CacheManager::clearImageCache(int olderThanDays) {
    // Mudar de 30 para 7 dias
    qint64 threshold = QDateTime::currentSecsSinceEpoch() - (7 * 86400);
    // ... resto do código
}
*/

// ============================================
// ECONOMIA ADICIONAL ESTIMADA: 15-25%
// ============================================
