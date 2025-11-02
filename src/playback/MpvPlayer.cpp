#include "MpvPlayer.h"
#include <QDebug>
#include <QVariantList>
#include <cstring>

MpvPlayer::MpvPlayer(QObject *parent) : QObject(parent) {
    m_mpv = mpv_create();
    if (!m_mpv) {
        qCritical() << "Failed to create mpv instance";
        return;
    }

    mpv_set_option_string(m_mpv, "vo", "null");
    mpv_set_option_string(m_mpv, "vid", "no");
    mpv_set_option_string(m_mpv, "gapless-audio", "yes");
    mpv_set_option_string(m_mpv, "prefetch-playlist", "yes");
    mpv_set_option_string(m_mpv, "cache", "yes");
    mpv_set_option_string(m_mpv, "cache-secs", "10");
    mpv_set_option_string(m_mpv, "load-scripts", "no");
    mpv_set_option_string(m_mpv, "ytdl", "no");
    mpv_set_option_string(m_mpv, "terminal", "no");
    mpv_set_option_string(m_mpv, "msg-level", "all=error");
    mpv_set_option_string(m_mpv, "volume-max", "400");
    mpv_set_option_string(m_mpv, "audio-normalize-downmix", "no");
    mpv_set_option_string(m_mpv, "loop-playlist", "no");
    mpv_set_option_string(m_mpv, "loop-file", "no");
    mpv_set_option_string(m_mpv, "keep-open", "yes");

    if (mpv_initialize(m_mpv) < 0) {
        qCritical() << "Failed to initialize mpv";
        mpv_destroy(m_mpv);
        m_mpv = nullptr;
        return;
    }

    mpv_set_property_string(m_mpv, "loop-file", "no");
    mpv_set_property_string(m_mpv, "loop-playlist", "no");

    mpv_observe_property(m_mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(m_mpv, 0, "playlist-pos", MPV_FORMAT_INT64);

    m_eventTimer = new QTimer(this);
    connect(m_eventTimer, &QTimer::timeout, this, &MpvPlayer::processEvents);
    m_eventTimer->start(50);
}

MpvPlayer::~MpvPlayer() {
    if (m_mpv) {
        mpv_terminate_destroy(m_mpv);
    }
}

void MpvPlayer::command(const QVariant &args) {
    if (!m_mpv) return;
    QVariantList list = args.value<QVariantList>();
    QVector<const char*> cargs;
    QVector<QByteArray> storage;
    for (const auto &arg : list) {
        storage.append(arg.toString().toUtf8());
        cargs.append(storage.last().constData());
    }
    cargs.append(nullptr);
    mpv_command_async(m_mpv, 0, cargs.data());
}

void MpvPlayer::setProperty(const QString &name, const QVariant &value) {
    if (!m_mpv) return;
    QByteArray nameUtf8 = name.toUtf8();
    if (value.metaType().id() == QMetaType::Double) {
        double val = value.toDouble();
        mpv_set_property_async(m_mpv, 0, nameUtf8.constData(), MPV_FORMAT_DOUBLE, &val);
    } else if (value.metaType().id() == QMetaType::Int || value.metaType().id() == QMetaType::LongLong) {
        int64_t val = value.toLongLong();
        mpv_set_property_async(m_mpv, 0, nameUtf8.constData(), MPV_FORMAT_INT64, &val);
    } else if (value.metaType().id() == QMetaType::Bool) {
        int val = value.toBool() ? 1 : 0;
        mpv_set_property_async(m_mpv, 0, nameUtf8.constData(), MPV_FORMAT_FLAG, &val);
    } else {
        QByteArray valUtf8 = value.toString().toUtf8();
        mpv_set_property_async(m_mpv, 0, nameUtf8.constData(), MPV_FORMAT_STRING, valUtf8.data());
    }
}

QVariant MpvPlayer::getProperty(const QString &name) const {
    if (!m_mpv) return QVariant();
    QByteArray nameUtf8 = name.toUtf8();
    double result;
    if (mpv_get_property(m_mpv, nameUtf8.constData(), MPV_FORMAT_DOUBLE, &result) >= 0) {
        return result;
    }
    return QVariant();
}

qint64 MpvPlayer::position() const {
    return getProperty("time-pos").toDouble() * 1000;
}

qint64 MpvPlayer::duration() const {
    return getProperty("duration").toDouble() * 1000;
}

bool MpvPlayer::isPaused() const {
    if (!m_mpv) return true;
    int paused = 0;
    if (mpv_get_property(m_mpv, "pause", MPV_FORMAT_FLAG, &paused) < 0) {
        return true;
    }
    return paused;
}

double MpvPlayer::volume() const {
    return getProperty("volume").toDouble();
}

void MpvPlayer::setVolume(double vol) {
    setProperty("volume", vol);
}

void MpvPlayer::processEvents() {
    if (!m_mpv) return;
    
    while (true) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) break;
        
        switch (event->event_id) {
        case MPV_EVENT_PROPERTY_CHANGE: {
            mpv_event_property *prop = (mpv_event_property *)event->data;
            if (prop->format == MPV_FORMAT_NONE) break;
            if (strcmp(prop->name, "time-pos") == 0) {
                emit positionChanged(position());
            } else if (strcmp(prop->name, "duration") == 0) {
                emit durationChanged(duration());
            } else if (strcmp(prop->name, "pause") == 0) {
                emit playbackStateChanged();
            } else if (strcmp(prop->name, "playlist-pos") == 0 && prop->format == MPV_FORMAT_INT64) {
                int64_t pos = *(int64_t *)prop->data;
                qDebug() << "[MPV] playlist-pos:" << pos;
                emit playlistPosChanged((int)pos);
            }
            break;
        }
        case MPV_EVENT_END_FILE: {
            mpv_event_end_file *ef = (mpv_event_end_file *)event->data;
            if (ef->reason == MPV_END_FILE_REASON_EOF) {
                qDebug() << "[MPV] END_FILE (EOF)";
                emit endOfFile();
            } else if (ef->reason == MPV_END_FILE_REASON_ERROR) {
                qWarning() << "MPV playback error:" << ef->error;
            } else if (ef->reason == MPV_END_FILE_REASON_STOP) {
                qDebug() << "[MPV] END_FILE (STOP)";
            }
            break;
        }
        case MPV_EVENT_PLAYBACK_RESTART:
            emit playbackStateChanged();
            break;
        default:
            break;
        }
    }
}
