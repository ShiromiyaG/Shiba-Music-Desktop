cmake_minimum_required(VERSION 3.21)
project(ShibaMusic LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /permissive-)
endif()

find_package(Qt6 6.9 REQUIRED COMPONENTS Quick QuickControls2 Network Multimedia Core5Compat)

qt_standard_project_setup()
set(CMAKE_AUTOMOC_COMPILER_PREDEFINES OFF)

qt_add_executable(shibamusic
    src/main.cpp
    src/core/SubsonicClient.h src/core/SubsonicClient.cpp
    src/playback/PlayerController.h src/playback/PlayerController.cpp
    src/core/SubsonicNetworkAccessManagerFactory.h
    src/core/SubsonicNetworkAccessManagerFactory.cpp
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

target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Multimedia Qt6::Core5Compat)