cmake_minimum_required(VERSION 3.21)

# Read version from file
file(READ "${CMAKE_SOURCE_DIR}/version.txt" APP_VERSION)
string(STRIP "${APP_VERSION}" APP_VERSION)

project(ShibaMusic VERSION ${APP_VERSION} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /permissive-)
endif()

# Discord Client ID (can be set via environment variable or CMake option)
if(DEFINED ENV{DISCORD_CLIENT_ID})
    set(DISCORD_CLIENT_ID "$ENV{DISCORD_CLIENT_ID}" CACHE STRING "Discord Application ID")
    message(STATUS "Discord Client ID: Set from environment (hidden)")
else()
    set(DISCORD_CLIENT_ID "" CACHE STRING "Discord Application ID")
    message(STATUS "Discord Client ID: Not set (Discord RPC will be disabled)")
endif()

find_package(Qt6 6.9 REQUIRED COMPONENTS Quick QuickControls2 Network Core5Compat Sql)

# Tentar encontrar libmpv no projeto primeiro
set(MPV_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/mpv/include")
set(MPV_LIBRARY_DIR "${CMAKE_SOURCE_DIR}/libs/mpv/lib")

set(RAPIDJSON_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/rapidjson/include")

if(EXISTS "${MPV_INCLUDE_DIR}/mpv/client.h")
    message(STATUS "Using libmpv from project: ${MPV_INCLUDE_DIR}")
    if(MINGW)
        set(MPV_LIBRARY "${MPV_LIBRARY_DIR}/libmpv.dll.a")
    else()
        set(MPV_LIBRARY "${MPV_LIBRARY_DIR}/mpv.lib")
    endif()
else()
    # Fallback to pkg-config (Linux/macOS only)
    find_package(PkgConfig)
    if(PkgConfig_FOUND)
        pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)
        set(MPV_INCLUDE_DIR ${MPV_INCLUDE_DIRS})
        set(MPV_LIBRARY PkgConfig::MPV)
        message(STATUS "Using libmpv from system via pkg-config")
    else()
        message(FATAL_ERROR "libmpv not found! Please:\n"
                           "  1. Download libmpv from: https://sourceforge.net/projects/mpv-player-windows/files/libmpv/\n"
                           "  2. Extract to: ${CMAKE_SOURCE_DIR}/libs/mpv/\n"
                           "  3. Structure: libs/mpv/include/ and libs/mpv/lib/\n"
                           "  See LIBMPV_SETUP.md for details.")
    endif()
endif()

qt_standard_project_setup()
set(CMAKE_AUTOMOC_COMPILER_PREDEFINES OFF)

qt_add_executable(shibamusic
    src/main.cpp
    src/core/SubsonicClient.h src/core/SubsonicClient.cpp
    src/core/CacheManager.h src/core/CacheManager.cpp
    src/playback/MpvPlayer.h src/playback/MpvPlayer.cpp
    src/playback/PlayerController.h src/playback/PlayerController.cpp
    src/playback/MediaControls.h src/playback/MediaControls.cpp
    src/playback/WindowsThumbnailToolbar.h src/playback/WindowsThumbnailToolbar.cpp
    src/core/SubsonicNetworkAccessManagerFactory.h
    src/core/SubsonicNetworkAccessManagerFactory.cpp
    src/core/WindowStateManager.h src/core/WindowStateManager.cpp
    src/core/AppInfo.h
    src/discord/DiscordRPC.h src/discord/DiscordRPC.cpp
    src/updater/UpdateChecker.h src/updater/UpdateChecker.cpp
    src/i18n/TranslationManager.h src/i18n/TranslationManager.cpp
)

# Define APP_VERSION and DISCORD_CLIENT_ID as preprocessor macros
target_compile_definitions(shibamusic PRIVATE 
    APP_VERSION="${APP_VERSION}"
    DISCORD_CLIENT_ID="${DISCORD_CLIENT_ID}"
)

if(WIN32)
    target_sources(shibamusic PRIVATE appicon.rc)
endif()

qt_add_resources(shibamusic "qml"
    PREFIX "/"
    FILES
        qml/main.qml
        qml/js/utils.js
        qml/components/NowPlayingBar.qml
        qml/components/ArtistCard.qml
        qml/components/AlbumCard.qml
        qml/components/TrackRow.qml
        qml/components/SectionHeader.qml
        qml/components/EmptyState.qml
        qml/components/QueueDrawer.qml
        qml/components/NowPlayingPanel.qml
        qml/components/UpdateDialog.qml
        qml/components/LanguageSelector.qml
        qml/components/ScrollConfig.qml
        qml/components/qmldir
        qml/pages/LoginPage.qml
        qml/pages/HomePage.qml
        qml/pages/ArtistPage.qml
        qml/pages/AlbumPage.qml
        qml/pages/ArtistsPage.qml
        qml/pages/AlbumsPage.qml
        qml/pages/FavoritesPage.qml
        qml/pages/PlaylistsPage.qml
        qml/pages/PlaylistDetailPage.qml
        qml/pages/SettingsPage.qml
        qml/pages/QueuePage.qml
        qml/icons/account_circle.svg
        qml/icons/add.svg
        qml/icons/album.svg
        qml/icons/arrow_upward.svg
        qml/icons/auto_awesome.svg
        qml/icons/check_box_outline_blank.svg
        qml/icons/close.svg
        qml/icons/home.svg
        qml/icons/mic.svg
        qml/icons/music_note.svg
        qml/icons/pause.svg
        qml/icons/play_arrow.svg
        qml/icons/queue_music.svg
        qml/icons/refresh.svg
        qml/icons/search.svg
        qml/icons/settings.svg
        qml/icons/shuffle.svg
        qml/icons/skip_next.svg
        qml/icons/skip_previous.svg
        qml/icons/star.svg
        qml/icons/favorite.svg
        qml/icons/favorite_border.svg
        qml/icons/volume_down.svg
        qml/icons/volume_mute.svg
        qml/icons/volume_off.svg
        qml/icons/volume_up.svg
        qml/icons/shiba_nobg_4k.ico
)

# Add translations as resources
qt_add_resources(shibamusic "translations"
    PREFIX "/i18n"
    BASE "${CMAKE_SOURCE_DIR}/i18n"
    FILES
        i18n/shibamusic_en.qm
        i18n/shibamusic_pt.qm
)

target_include_directories(shibamusic PRIVATE ${MPV_INCLUDE_DIR} ${RAPIDJSON_INCLUDE_DIR})

if(TARGET PkgConfig::MPV)
    target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Core5Compat Qt6::Sql PkgConfig::MPV)
else()
    target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Core5Compat Qt6::Sql ${MPV_LIBRARY})
endif()

# Windows-specific libraries for SMTC
if(WIN32)
    if(MSVC)
        # MSVC: Full WinRT support
        target_link_libraries(shibamusic PRIVATE runtimeobject windowsapp)
        target_compile_definitions(shibamusic PRIVATE WINAPI_FAMILY=WINAPI_FAMILY_DESKTOP_APP)
        set_target_properties(shibamusic PROPERTIES
            VS_WINDOWS_TARGET_PLATFORM_MIN_VERSION "10.0.17763.0"
        )
        message(STATUS "Building with MSVC - Full Windows SMTC support enabled")
    else()
        # MinGW: Limited support
        target_link_libraries(shibamusic PRIVATE runtimeobject)
        message(STATUS "Building with MinGW - Limited SMTC support (keyboard shortcuts only)")
    endif()
endif()

if(NOT TARGET PkgConfig::MPV)
    # Copiar DLL do mpv para a pasta de build
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/mpv/bin/libmpv-2.dll")
        add_custom_command(TARGET shibamusic POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_SOURCE_DIR}/libs/mpv/bin/libmpv-2.dll"
            "$<TARGET_FILE_DIR:shibamusic>/libmpv-2.dll"
            COMMENT "Copiando libmpv-2.dll para pasta de build"
        )
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/libs/mpv/bin/mpv-2.dll")
        add_custom_command(TARGET shibamusic POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_SOURCE_DIR}/libs/mpv/bin/mpv-2.dll"
            "$<TARGET_FILE_DIR:shibamusic>/mpv-2.dll"
            COMMENT "Copiando mpv-2.dll para pasta de build"
        )
    else()
        message(WARNING "DLL do mpv não encontrada em libs/mpv/bin/")
    endif()
endif()

# Copy pre-built updater.exe to build directory
if(EXISTS "${CMAKE_SOURCE_DIR}/updater/updater.exe")
    add_custom_command(TARGET shibamusic POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/updater/updater.exe"
        "$<TARGET_FILE_DIR:shibamusic>/updater.exe"
        COMMENT "Copying updater.exe to build directory"
    )
endif()
