#include "CacheManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QBuffer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QDebug>

CacheManager::CacheManager(QObject *parent) : QObject(parent) {
    m_cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(m_cachePath);
    m_imageMemoryCache.setMaxCost(50 * 1024 * 1024); // 50MB limit
}

CacheManager::~CacheManager() {
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool CacheManager::initialize() {
    m_db = QSqlDatabase::addDatabase("QSQLITE", "cache_connection");
    m_db.setDatabaseName(m_cachePath + "/shibamusic_cache.db");
    
    if (!m_db.open()) {
        qWarning() << "Failed to open cache database:" << m_db.lastError().text();
        return false;
    }
    
    createTables();
    qDebug() << "Cache database initialized at:" << m_db.databaseName();
    return true;
}

void CacheManager::createTables() {
    QSqlQuery query(m_db);
    
    // Image cache table
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS image_cache (
            url TEXT PRIMARY KEY,
            data BLOB NOT NULL,
            cached_at INTEGER NOT NULL,
            size INTEGER NOT NULL
        )
    )");
    
    // Metadata cache table (albums, artists, tracks)
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS metadata_cache (
            type TEXT NOT NULL,
            id TEXT NOT NULL,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL,
            PRIMARY KEY (type, id)
        )
    )");
    
    // List cache table (artists list, albums list, etc)
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS list_cache (
            type TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
        )
    )");
    
    // Create indices for faster queries
    query.exec("CREATE INDEX IF NOT EXISTS idx_image_cached_at ON image_cache(cached_at)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_metadata_cached_at ON metadata_cache(cached_at)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_list_cached_at ON list_cache(cached_at)");
}

QString CacheManager::getCachePath() {
    return m_cachePath;
}

// Image cache methods
bool CacheManager::hasImage(const QString& url) {
    QSqlQuery query(m_db);
    query.prepare("SELECT 1 FROM image_cache WHERE url = ?");
    query.addBindValue(url);
    
    if (query.exec() && query.next()) {
        return true;
    }
    return false;
}

QPixmap CacheManager::getImage(const QString& url) {
    if (QPixmap *cached = m_imageMemoryCache.object(url)) {
        return *cached;
    }
    
    QSqlQuery query(m_db);
    query.prepare("SELECT data FROM image_cache WHERE url = ?");
    query.addBindValue(url);
    
    if (query.exec() && query.next()) {
        QByteArray data = query.value(0).toByteArray();
        QPixmap pixmap;
        if (pixmap.loadFromData(data)) {
            int cost = pixmap.width() * pixmap.height() * pixmap.depth() / 8;
            m_imageMemoryCache.insert(url, new QPixmap(pixmap), cost);
            return pixmap;
        }
    }
    
    return QPixmap();
}

void CacheManager::saveImage(const QString& url, const QPixmap& pixmap) {
    int cost = pixmap.width() * pixmap.height() * pixmap.depth() / 8;
    m_imageMemoryCache.insert(url, new QPixmap(pixmap), cost);
    
    QByteArray data;
    QBuffer buffer(&data);
    buffer.open(QIODevice::WriteOnly);
    
    if (!pixmap.save(&buffer, "JPEG", 90)) {
        qWarning() << "Failed to convert pixmap to JPEG for caching";
        return;
    }
    
    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT OR REPLACE INTO image_cache (url, data, cached_at, size)
        VALUES (?, ?, ?, ?)
    )");
    query.addBindValue(url);
    query.addBindValue(data);
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    query.addBindValue(data.size());
    
    if (query.exec()) {
        emit imageCached(url);
    } else {
        qWarning() << "Failed to save image to cache:" << query.lastError().text();
    }
}

void CacheManager::clearImageCache(int olderThanDays) {
    QSqlQuery query(m_db);
    qint64 threshold = QDateTime::currentSecsSinceEpoch() - (olderThanDays * 86400);
    
    query.prepare("DELETE FROM image_cache WHERE cached_at < ?");
    query.addBindValue(threshold);
    
    if (query.exec()) {
        qDebug() << "Cleared" << query.numRowsAffected() << "old images from cache";
    }
}

// Metadata cache methods
bool CacheManager::hasMetadata(const QString& type, const QString& id) {
    QSqlQuery query(m_db);
    query.prepare("SELECT 1 FROM metadata_cache WHERE type = ? AND id = ?");
    query.addBindValue(type);
    query.addBindValue(id);
    
    if (query.exec() && query.next()) {
        return true;
    }
    return false;
}

QVariantMap CacheManager::getMetadata(const QString& type, const QString& id) {
    QSqlQuery query(m_db);
    query.prepare("SELECT data FROM metadata_cache WHERE type = ? AND id = ?");
    query.addBindValue(type);
    query.addBindValue(id);
    
    if (query.exec() && query.next()) {
        QString jsonStr = query.value(0).toString();
        QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
        return doc.object().toVariantMap();
    }
    
    return QVariantMap();
}

void CacheManager::saveMetadata(const QString& type, const QString& id, const QVariantMap& data) {
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    QString jsonStr = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
    
    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT OR REPLACE INTO metadata_cache (type, id, data, cached_at)
        VALUES (?, ?, ?, ?)
    )");
    query.addBindValue(type);
    query.addBindValue(id);
    query.addBindValue(jsonStr);
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    
    if (!query.exec()) {
        qWarning() << "Failed to save metadata to cache:" << query.lastError().text();
    }
}

void CacheManager::clearMetadataCache(int olderThanDays) {
    QSqlQuery query(m_db);
    qint64 threshold = QDateTime::currentSecsSinceEpoch() - (olderThanDays * 86400);
    
    query.prepare("DELETE FROM metadata_cache WHERE cached_at < ?");
    query.addBindValue(threshold);
    
    if (query.exec()) {
        qDebug() << "Cleared" << query.numRowsAffected() << "old metadata entries from cache";
    }
}

// List cache methods
bool CacheManager::hasList(const QString& type) {
    QSqlQuery query(m_db);
    query.prepare("SELECT 1 FROM list_cache WHERE type = ?");
    query.addBindValue(type);
    
    if (query.exec() && query.next()) {
        return true;
    }
    return false;
}

QVariantList CacheManager::getList(const QString& type) {
    QSqlQuery query(m_db);
    query.prepare("SELECT data FROM list_cache WHERE type = ?");
    query.addBindValue(type);
    
    if (query.exec() && query.next()) {
        QString jsonStr = query.value(0).toString();
        QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
        return doc.array().toVariantList();
    }
    
    return QVariantList();
}

void CacheManager::saveList(const QString& type, const QVariantList& data) {
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    QString jsonStr = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
    
    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT OR REPLACE INTO list_cache (type, data, cached_at)
        VALUES (?, ?, ?)
    )");
    query.addBindValue(type);
    query.addBindValue(jsonStr);
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    
    if (!query.exec()) {
        qWarning() << "Failed to save list to cache:" << query.lastError().text();
    }
}

void CacheManager::clearListCache() {
    QSqlQuery query(m_db);
    if (query.exec("DELETE FROM list_cache")) {
        qDebug() << "Cleared all list cache";
    }
}

// Statistics methods
qint64 CacheManager::getCacheSize() {
    QSqlQuery query(m_db);
    query.exec("SELECT SUM(size) FROM image_cache");
    
    if (query.next()) {
        return query.value(0).toLongLong();
    }
    return 0;
}

int CacheManager::getImageCount() {
    QSqlQuery query(m_db);
    query.exec("SELECT COUNT(*) FROM image_cache");
    
    if (query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}

void CacheManager::clearAllCache() {
    m_imageMemoryCache.clear();
    QSqlQuery query(m_db);
    query.exec("DELETE FROM image_cache");
    query.exec("DELETE FROM metadata_cache");
    query.exec("DELETE FROM list_cache");
    query.exec("VACUUM");
    
    qDebug() << "Cleared all cache data";
    emit cacheCleared();
}
