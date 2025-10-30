#pragma once
#include <QObject>
#include <QTimer>
#include <QVariant>
#include <mpv/client.h>

class MpvPlayer : public QObject {
    Q_OBJECT
public:
    explicit MpvPlayer(QObject *parent = nullptr);
    ~MpvPlayer();

    void command(const QVariant &args);
    void setProperty(const QString &name, const QVariant &value);
    QVariant getProperty(const QString &name) const;
    
    qint64 position() const;
    qint64 duration() const;
    bool isPaused() const;
    double volume() const;
    void setVolume(double vol);

signals:
    void positionChanged(qint64 pos);
    void durationChanged(qint64 dur);
    void playbackStateChanged();
    void endOfFile();
    void playlistPosChanged(int pos);

private slots:
    void processEvents();

private:
    mpv_handle *m_mpv = nullptr;
    QTimer *m_eventTimer = nullptr;
};
