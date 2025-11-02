#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QPixmap>
#include <QVariantMap>
#include <QVariantList>
#include <QCache>

class CacheManager : public QObject {
    Q_OBJECT

public:
    explicit CacheManager(QObject *parent = nullptr);
    ~CacheManager();

    bool initialize();
    
    // Image cache
    Q_INVOKABLE bool hasImage(const QString& url);
    Q_INVOKABLE QPixmap getImage(const QString& url);
    Q_INVOKABLE void saveImage(const QString& url, const QPixmap& pixmap);
    Q_INVOKABLE void clearImageCache(int olderThanDays = 30);
    
    // Metadata cache
    Q_INVOKABLE bool hasMetadata(const QString& type, const QString& id);
    Q_INVOKABLE QVariantMap getMetadata(const QString& type, const QString& id);
    Q_INVOKABLE void saveMetadata(const QString& type, const QString& id, const QVariantMap& data);
    Q_INVOKABLE void clearMetadataCache(int olderThanDays = 7);
    
    // List cache (artists, albums, playlists)
    Q_INVOKABLE bool hasList(const QString& type);
    Q_INVOKABLE QVariantList getList(const QString& type);
    Q_INVOKABLE void saveList(const QString& type, const QVariantList& data);
    Q_INVOKABLE void clearListCache();
    
    // Cache statistics
    Q_INVOKABLE qint64 getCacheSize();
    Q_INVOKABLE int getImageCount();
    Q_INVOKABLE void clearAllCache();

signals:
    void cacheCleared();
    void imageCached(const QString& url);

private:
    void createTables();
    QString getCachePath();
    
    QSqlDatabase m_db;
    QString m_cachePath;
    QCache<QString, QPixmap> m_imageMemoryCache;
};
