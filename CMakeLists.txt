cmake_minimum_required(VERSION 3.21)
project(ShibaMusic LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /permissive-)
endif()

find_package(Qt6 6.9 REQUIRED COMPONENTS Quick QuickControls2 Network Core5Compat)

# Tentar encontrar libmpv no projeto primeiro
set(MPV_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/mpv/include")
set(MPV_LIBRARY_DIR "${CMAKE_SOURCE_DIR}/libs/mpv/lib")

set(RAPIDJSON_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/rapidjson/include")

if(EXISTS "${MPV_INCLUDE_DIR}/mpv/client.h")
    message(STATUS "Usando libmpv do projeto: ${MPV_INCLUDE_DIR}")
    if(MINGW)
        set(MPV_LIBRARY "${MPV_LIBRARY_DIR}/libmpv.dll.a")
    else()
        set(MPV_LIBRARY "${MPV_LIBRARY_DIR}/mpv.lib")
    endif()
else()
    # Fallback para pkg-config
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)
    set(MPV_INCLUDE_DIR ${MPV_INCLUDE_DIRS})
    set(MPV_LIBRARY PkgConfig::MPV)
endif()

qt_standard_project_setup()
set(CMAKE_AUTOMOC_COMPILER_PREDEFINES OFF)

# Application ID do Discord (opcional)
if(DEFINED ENV{DISCORD_APP_ID})
    set(DISCORD_APP_ID $ENV{DISCORD_APP_ID})
else()
    set(DISCORD_APP_ID "")
endif()

configure_file(
    "${CMAKE_SOURCE_DIR}/src/config.h.in"
    "${CMAKE_BINARY_DIR}/config.h"
)

qt_add_executable(shibamusic
    src/main.cpp
    src/core/SubsonicClient.h src/core/SubsonicClient.cpp
    src/playback/MpvPlayer.h src/playback/MpvPlayer.cpp
    src/playback/PlayerController.h src/playback/PlayerController.cpp
    src/core/SubsonicNetworkAccessManagerFactory.h
    src/core/SubsonicNetworkAccessManagerFactory.cpp
    src/discord/DiscordRPC.h src/discord/DiscordRPC.cpp
)

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
        qml/pages/LoginPage.qml
        qml/pages/HomePage.qml
        qml/pages/ArtistPage.qml
        qml/pages/AlbumPage.qml
        qml/pages/ArtistsPage.qml
        qml/pages/AlbumsPage.qml
        qml/pages/FavoritesPage.qml
        qml/pages/SettingsPage.qml
        qml/icons/account_circle.svg
        qml/icons/add.svg
        qml/icons/album.svg
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
        qml/icons/volume_down.svg
        qml/icons/volume_mute.svg
        qml/icons/volume_off.svg
        qml/icons/volume_up.svg
)

target_include_directories(shibamusic PRIVATE ${MPV_INCLUDE_DIR} ${RAPIDJSON_INCLUDE_DIR} ${CMAKE_BINARY_DIR})

if(TARGET PkgConfig::MPV)
    target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Core5Compat PkgConfig::MPV)
else()
    target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Core5Compat ${MPV_LIBRARY})
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
