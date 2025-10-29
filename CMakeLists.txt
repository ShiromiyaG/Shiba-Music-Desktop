cmake_minimum_required(VERSION 3.21)
project(ShibaMusic LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /permissive-)
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 Network Multimedia)

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
        qml/components/NowPlayingBar.qml
        qml/components/ArtistCard.qml
        qml/components/AlbumCard.qml
        qml/components/TrackRow.qml
        qml/components/SectionHeader.qml
        qml/components/EmptyState.qml
        qml/components/QueueDrawer.qml
        qml/pages/LoginPage.qml
        qml/pages/HomePage.qml
        qml/pages/ArtistPage.qml
        qml/pages/AlbumPage.qml
)

target_link_libraries(shibamusic PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Multimedia)
