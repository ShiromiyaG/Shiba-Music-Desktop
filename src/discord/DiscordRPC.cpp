#include "DiscordRPC.h"

#include <QCoreApplication>

#include <QDateTime>

#include <QDebug>

#include <QJsonDocument>

#include <QJsonObject>

#include <QJsonValue>

#include <QUuid>

#include <QtGlobal>

#include <QByteArray>

#include <QProcessEnvironment>

#include <QDir>

#include <QFile>

#include <QStringList>

#include <QtEndian>

#include <QTimer>

#include <cstring>

#ifdef Q_OS_WIN

#include <qt_windows.h>

#else

#include <cerrno>

#include <fcntl.h>

#include <sys/stat.h>

#include <unistd.h>

#include <poll.h>

#endif

namespace

{

    constexpr qintptr kInvalidHandle = -1;

    constexpr quint32 kOpcodeHandshake = 0;

    constexpr quint32 kOpcodeFrame = 1;

    constexpr quint32 kOpcodeClose = 2;

    constexpr quint32 kOpcodePing = 3;

    constexpr quint32 kOpcodePong = 4;

    bool isListeningState(bool playing, bool showPaused)

    {

        return playing || showPaused;
    }

} // namespace

DiscordRPC::DiscordRPC(QObject *parent) : QObject(parent)

{
    // Get Discord Client ID from environment variable, or use compiled-in default
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    
    // Priority: 1. Environment variable, 2. Compiled-in ID
    QString envClientId = env.value("DISCORD_CLIENT_ID", "");
    QString compiledClientId = QString(DISCORD_CLIENT_ID);
    
    if (!envClientId.isEmpty())
    {
        // Use environment variable if set (for development/testing)
        m_clientId = envClientId;
        qDebug() << "Discord: Using Client ID from environment variable";
    }
    else if (!compiledClientId.isEmpty())
    {
        // Use compiled-in ID (for production builds)
        m_clientId = compiledClientId;
        qDebug() << "Discord: Using compiled-in Client ID";
    }
    else
    {
        // No ID available
        m_clientId = "";
    }

    // Disable Discord RPC if no Client ID is provided
    if (m_clientId.isEmpty())
    {
        qDebug() << "Discord Client ID not set. Discord Rich Presence disabled.";
        qDebug() << "Set DISCORD_CLIENT_ID environment variable or compile with ID to enable it.";
        m_enabled = false;
    }

    m_pollTimer = new QTimer(this);

    m_pollTimer->setInterval(1000);

    connect(m_pollTimer, &QTimer::timeout, this, &DiscordRPC::processIncomingFrames);

    m_pollTimer->start();

    if (m_enabled)

        initialize();
}

DiscordRPC::~DiscordRPC()

{

    shutdown();
}

void DiscordRPC::setEnabled(bool enabled)

{

    if (m_enabled == enabled)

        return;

    m_enabled = enabled;

    if (enabled)

        initialize();

    else

        shutdown();

    emit enabledChanged();

    qDebug() << "Discord RPC: Enabled set to" << enabled;
}

void DiscordRPC::setShowPaused(bool show)

{

    if (m_showPaused == show)

        return;

    m_showPaused = show;

    emit showPausedChanged();

    if (!show && !m_lastPlaying)

        clearPresence();
}

void DiscordRPC::setClientId(const QString &id)

{

    if (m_clientId == id)

        return;

    bool wasInitialized = m_initialized;

    if (wasInitialized)

        shutdown();

    m_clientId = id;

    if (wasInitialized && m_enabled)

        initialize();

    emit clientIdChanged();
}

void DiscordRPC::initialize()

{

    if (!m_enabled)

        return;

    if (m_clientId.isEmpty())

    {

        qWarning() << "Discord RPC: Cannot initialize without client ID";

        return;
    }

    if (!ensureConnection())

    {

        qWarning() << "Discord RPC: Failed to connect to Discord IPC";

        return;
    }

    if (!m_initialized)

    {

        m_initialized = true;

        qDebug() << "Discord RPC: Initialized with client ID" << m_clientId;

        emit ready();
    }
}

void DiscordRPC::resetLastPresence()

{

    m_lastTitle.clear();

    m_lastArtist.clear();

    m_lastAlbum.clear();

    m_lastCoverUrl.clear();

    m_lastTrackId.clear();

    m_lastPlaying = false;

    m_lastPosition = 0;

    m_lastDuration = 0;
}

void DiscordRPC::shutdown()

{

    if (!m_initialized && !m_connectionReady)

        return;

    if (m_connectionReady)

    {

        QJsonObject payload;

        payload.insert(QStringLiteral("cmd"), QStringLiteral("SET_ACTIVITY"));

        QJsonObject args;

        args.insert(QStringLiteral("pid"), static_cast<qint64>(QCoreApplication::applicationPid()));

        args.insert(QStringLiteral("activity"), QJsonValue(QJsonValue::Null));

        payload.insert(QStringLiteral("args"), args);

        payload.insert(QStringLiteral("nonce"), QUuid::createUuid().toString(QUuid::WithoutBraces));

        sendCommand(payload);
    }

    closeConnection();

    resetLastPresence();

    qDebug() << "Discord RPC: Shutdown";
}

void DiscordRPC::updatePresence(const QString &title, const QString &artist,
                                const QString &album, bool playing,
                                qint64 position, qint64 duration,
                                const QString &coverArtUrl,
                                const QString &trackId)
{
    if (!m_enabled)
        return;

    if (!m_initialized)
        initialize();

    if (!m_initialized)
        return;

    const bool trackChanged = !trackId.isEmpty() && trackId != m_lastTrackId;

    if (!playing && !m_showPaused)
    {
        clearPresence();
        resetLastPresence();
        return;
    }

    qint64 effectiveDuration = duration > 0 ? duration : 0;
    qint64 effectivePosition = position;

    if (trackChanged || effectivePosition < 0 ||
        (effectiveDuration > 0 && effectivePosition > effectiveDuration + 1000))
    {
        effectivePosition = 0;
    }

    const bool shouldSkip =
        !trackChanged &&
        title == m_lastTitle && artist == m_lastArtist &&
        album == m_lastAlbum && playing == m_lastPlaying &&
        effectiveDuration == m_lastDuration &&
        qAbs(effectivePosition - m_lastPosition) < 1000;

    if (shouldSkip)
        return;

    m_lastTitle = title;
    m_lastArtist = artist;
    m_lastAlbum = album;
    m_lastPlaying = playing;
    m_lastPosition = effectivePosition;
    m_lastDuration = effectiveDuration;
    m_lastCoverUrl = coverArtUrl;
    if (!trackId.isEmpty())
        m_lastTrackId = trackId;

    QJsonObject activity;
    activity.insert(QStringLiteral("type"), isListeningState(playing, m_showPaused) ? 2 : 0);

    const QString heading = !artist.isEmpty()  ? artist
                            : !title.isEmpty() ? title
                                               : album;
    if (!heading.isEmpty())
    {
        activity.insert(QStringLiteral("name"), heading);
        activity.insert(QStringLiteral("status_display_type"), 0);
    }

    if (!title.isEmpty())
        activity.insert(QStringLiteral("details"), title);
    if (!artist.isEmpty())
        activity.insert(QStringLiteral("state"), artist);

    QJsonObject assets;
    if (!album.isEmpty())
        assets.insert(QStringLiteral("large_text"), album);

    if (!coverArtUrl.isEmpty())
    {
        assets.insert(QStringLiteral("large_image"), coverArtUrl);
        assets.insert(QStringLiteral("large_url"), coverArtUrl);
    }

    assets.insert(QStringLiteral("small_image"), playing ? QStringLiteral("play")
                                                         : QStringLiteral("pause"));
    assets.insert(QStringLiteral("small_text"), playing ? QStringLiteral("Playing")
                                                        : QStringLiteral("Paused"));
    activity.insert(QStringLiteral("assets"), assets);

    if (effectiveDuration > 0 && playing)
    {
        const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
        const qint64 startMs = nowMs - effectivePosition;
        const qint64 endMs = startMs + effectiveDuration;
        if (startMs < endMs)
        {
            QJsonObject timestamps;
            const qint64 startSeconds = startMs / 1000;
            const qint64 endSeconds = endMs / 1000;
            timestamps.insert(QStringLiteral("start"), startSeconds);
            timestamps.insert(QStringLiteral("end"), endSeconds);
            activity.insert(QStringLiteral("timestamps"), timestamps);
        }
    }

    qDebug() << "Discord RPC: Activity payload"
             << QJsonDocument(activity).toJson(QJsonDocument::Compact);

    if (!sendActivityPayload(activity))
    {
        qWarning() << "Discord RPC: Failed to update activity";
    }
    else
    {
        qDebug() << "Discord RPC: Updated activity -" << title << "by" << artist;
    }
}
void DiscordRPC::clearPresence()

{

    if (!m_enabled)

        return;

    if (!m_initialized)

        initialize();

    if (!m_initialized)

        return;

    QJsonObject payload;

    payload.insert(QStringLiteral("cmd"), QStringLiteral("SET_ACTIVITY"));

    QJsonObject args;

    args.insert(QStringLiteral("pid"), static_cast<qint64>(QCoreApplication::applicationPid()));

    args.insert(QStringLiteral("activity"), QJsonValue(QJsonValue::Null));

    payload.insert(QStringLiteral("args"), args);

    payload.insert(QStringLiteral("nonce"), QUuid::createUuid().toString(QUuid::WithoutBraces));

    if (!sendCommand(payload))

    {

        qWarning() << "Discord RPC: Failed to clear activity";
    }

    else

    {

        qDebug() << "Discord RPC: Cleared";
    }
}

bool DiscordRPC::ensureConnection()

{

    if (m_connectionReady)

        return true;

    if (!openIpcConnection())

        return false;

    if (!sendHandshake())

    {

        closeConnection();

        return false;
    }

    m_connectionReady = true;

    return true;
}

bool DiscordRPC::openIpcConnection()

{

    closeConnection();

#ifdef Q_OS_WIN

    for (int i = 0; i < 10; ++i)

    {

        const QString pipePath = QStringLiteral(R"(\\?\pipe\discord-ipc-%1)").arg(i);

        const std::wstring pipePathW = pipePath.toStdWString();

        HANDLE handle = CreateFileW(pipePathW.c_str(),

                                    GENERIC_READ | GENERIC_WRITE,

                                    0,

                                    nullptr,

                                    OPEN_EXISTING,

                                    FILE_ATTRIBUTE_NORMAL,

                                    nullptr);

        if (handle == INVALID_HANDLE_VALUE)

        {

            if (GetLastError() == ERROR_PIPE_BUSY)

            {

                if (WaitNamedPipeW(pipePathW.c_str(), 500))

                {

                    handle = CreateFileW(pipePathW.c_str(),

                                         GENERIC_READ | GENERIC_WRITE,

                                         0,

                                         nullptr,

                                         OPEN_EXISTING,

                                         FILE_ATTRIBUTE_NORMAL,

                                         nullptr);
                }
            }
        }

        if (handle != INVALID_HANDLE_VALUE)

        {

            m_ipcHandle = reinterpret_cast<qintptr>(handle);

            return true;
        }
    }

#else

    QStringList baseDirs;

    const QString xdgRuntime = qEnvironmentVariable("XDG_RUNTIME_DIR");

    if (!xdgRuntime.isEmpty())

        baseDirs << xdgRuntime;

    const QString tmpDirEnv = qEnvironmentVariable("TMPDIR");

    if (!tmpDirEnv.isEmpty())

        baseDirs << tmpDirEnv;

    baseDirs << QStringLiteral("/tmp");

    for (const QString &base : baseDirs)

    {

        for (int i = 0; i < 10; ++i)

        {

            const QString socketPath = QDir(base).filePath(QStringLiteral("discord-ipc-%1").arg(i));

            QByteArray nativePath = QFile::encodeName(socketPath);

            int fd = ::open(nativePath.constData(), O_RDWR);

            if (fd >= 0)

            {

                m_ipcHandle = static_cast<qintptr>(fd);

                return true;
            }
        }
    }

#endif

    return false;
}

bool DiscordRPC::sendHandshake()

{

    QJsonObject handshake;

    handshake.insert(QStringLiteral("v"), 1);

    handshake.insert(QStringLiteral("client_id"), m_clientId);

    const QByteArray payload = QJsonDocument(handshake).toJson(QJsonDocument::Compact);

    if (!writeFrame(kOpcodeHandshake, payload))

        return false;

    quint32 opcode = 0;

    QByteArray responsePayload;

    while (readFrame(opcode, responsePayload))

    {

        if (opcode == kOpcodeFrame)

        {

            QJsonDocument doc = QJsonDocument::fromJson(responsePayload);

            const QJsonObject obj = doc.object();

            if (obj.value(QStringLiteral("cmd")).toString() == QLatin1String("DISPATCH") &&

                obj.value(QStringLiteral("evt")).toString() == QLatin1String("READY"))

            {

                return true;
            }
        }

        else if (opcode == kOpcodePing)

        {

            writeFrame(kOpcodePong, responsePayload);
        }

        else if (opcode == kOpcodeClose)

        {

            return false;
        }
    }

    return false;
}

bool DiscordRPC::sendCommand(const QJsonObject &payload)

{

    if (!ensureConnection())

        return false;

    const QByteArray bytes = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    if (!writeFrame(kOpcodeFrame, bytes))

    {

        closeConnection();

        return false;
    }

    return true;
}

bool DiscordRPC::sendActivityPayload(const QJsonObject &activity)

{

    QJsonObject payload;

    payload.insert(QStringLiteral("cmd"), QStringLiteral("SET_ACTIVITY"));

    QJsonObject args;

    args.insert(QStringLiteral("pid"), static_cast<qint64>(QCoreApplication::applicationPid()));

    args.insert(QStringLiteral("activity"), activity);

    payload.insert(QStringLiteral("args"), args);

    payload.insert(QStringLiteral("nonce"), QUuid::createUuid().toString(QUuid::WithoutBraces));

    return sendCommand(payload);
}

bool DiscordRPC::writeFrame(quint32 opcode, const QByteArray &payload)

{

    QByteArray buffer;

    buffer.resize(static_cast<int>(sizeof(quint32) * 2));

    quint32 length = static_cast<quint32>(payload.size());

    std::memcpy(buffer.data(), &opcode, sizeof(quint32));

    std::memcpy(buffer.data() + sizeof(quint32), &length, sizeof(quint32));

#if Q_BYTE_ORDER == Q_BIG_ENDIAN

    opcode = qToLittleEndian(opcode);

    length = qToLittleEndian(length);

    std::memcpy(buffer.data(), &opcode, sizeof(quint32));

    std::memcpy(buffer.data() + sizeof(quint32), &length, sizeof(quint32));

#endif

    QByteArray combined = buffer;

    combined.append(payload);

    if (!writeAll(combined))

        return false;

    return true;
}

bool DiscordRPC::readFrame(quint32 &opcode, QByteArray &payload)

{

    QByteArray header = readExact(static_cast<qint64>(sizeof(quint32) * 2));

    if (header.size() != static_cast<int>(sizeof(quint32) * 2))

        return false;

    std::memcpy(&opcode, header.constData(), sizeof(quint32));

    quint32 length = 0;

    std::memcpy(&length, header.constData() + sizeof(quint32), sizeof(quint32));

#if Q_BYTE_ORDER == Q_BIG_ENDIAN

    opcode = qFromLittleEndian(opcode);

    length = qFromLittleEndian(length);

#endif

    payload = length > 0 ? readExact(length) : QByteArray();

    if (payload.size() != static_cast<int>(length))

        return false;

    return true;
}

QByteArray DiscordRPC::readExact(qint64 size)

{

    if (size <= 0)

        return QByteArray();

    QByteArray buffer;

    buffer.resize(static_cast<int>(size));

    qint64 totalRead = 0;

    char *dataPtr = buffer.data();

    while (totalRead < size)

    {

#ifdef Q_OS_WIN

        DWORD bytesRead = 0;

        HANDLE handle = reinterpret_cast<HANDLE>(m_ipcHandle);

        if (!ReadFile(handle, dataPtr + totalRead, static_cast<DWORD>(size - totalRead), &bytesRead, nullptr) ||

            bytesRead == 0)

        {

            return QByteArray();
        }

        totalRead += bytesRead;

#else

        const ssize_t result = ::read(static_cast<int>(m_ipcHandle), dataPtr + totalRead, size - totalRead);

        if (result < 0)

        {

            if (errno == EINTR)

                continue;

            return QByteArray();
        }

        if (result == 0)

            return QByteArray();

        totalRead += result;

#endif
    }

    return buffer;
}

void DiscordRPC::closeConnection()

{

    if (m_ipcHandle == kInvalidHandle)

        return;

#ifdef Q_OS_WIN

    HANDLE handle = reinterpret_cast<HANDLE>(m_ipcHandle);

    CloseHandle(handle);

#else

    ::close(static_cast<int>(m_ipcHandle));

#endif

    m_ipcHandle = kInvalidHandle;

    m_connectionReady = false;

    m_initialized = false;
}

bool DiscordRPC::writeAll(const QByteArray &data)

{

    if (m_ipcHandle == kInvalidHandle)

        return false;

    const char *ptr = data.constData();

    const qint64 totalSize = data.size();

    qint64 written = 0;

    while (written < totalSize)

    {

#ifdef Q_OS_WIN

        DWORD bytesWritten = 0;

        HANDLE handle = reinterpret_cast<HANDLE>(m_ipcHandle);

        if (!WriteFile(handle, ptr + written, static_cast<DWORD>(totalSize - written), &bytesWritten, nullptr))

        {

            return false;
        }

        if (bytesWritten == 0)

            return false;

        written += bytesWritten;

#else

        const ssize_t result = ::write(static_cast<int>(m_ipcHandle), ptr + written, totalSize - written);

        if (result < 0)

        {

            if (errno == EINTR)

                continue;

            return false;
        }

        if (result == 0)

            return false;

        written += result;

#endif
    }

    return true;
}

void DiscordRPC::processIncomingFrames()

{

    if (!m_connectionReady)

        return;

    while (hasPendingFrame())

    {

        quint32 opcode = 0;

        QByteArray payload;

        if (!readFrame(opcode, payload))

        {

            qWarning() << "Discord RPC: Failed to read incoming frame";

            closeConnection();

            break;
        }

        if (opcode == kOpcodePing)

        {

            writeFrame(kOpcodePong, payload);
        }

        else if (opcode == kOpcodeClose)

        {

            qWarning() << "Discord RPC: Connection closed by Discord";

            closeConnection();

            break;
        }
    }
}

bool DiscordRPC::hasPendingFrame() const

{

    if (!m_connectionReady || m_ipcHandle == kInvalidHandle)

        return false;

#ifdef Q_OS_WIN

    DWORD bytesAvailable = 0;

    if (!PeekNamedPipe(reinterpret_cast<HANDLE>(m_ipcHandle), nullptr, 0, nullptr, &bytesAvailable, nullptr))

        return false;

    return bytesAvailable >= sizeof(quint32) * 2;

#else

    struct pollfd fd;

    fd.fd = static_cast<int>(m_ipcHandle);

    fd.events = POLLIN;

    fd.revents = 0;

    const int result = ::poll(&fd, 1, 0);

    if (result > 0 && (fd.revents & (POLLIN | POLLERR | POLLHUP)))

        return (fd.revents & POLLIN) != 0;

    return false;

#endif
}
