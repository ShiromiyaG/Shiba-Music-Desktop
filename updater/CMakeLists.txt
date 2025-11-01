cmake_minimum_required(VERSION 3.21)

project(ShibaMusicUpdater LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_AUTOUIC OFF)
set(CMAKE_AUTORCC OFF)

add_executable(updater WIN32 main.cpp)
target_link_libraries(updater PRIVATE shell32)

if(MSVC)
    target_compile_options(updater PRIVATE /W3)
    target_link_options(updater PRIVATE /SUBSYSTEM:WINDOWS)
else()
    target_compile_options(updater PRIVATE -mwindows)
    target_link_options(updater PRIVATE -static)
endif()

install(TARGETS updater DESTINATION .)
