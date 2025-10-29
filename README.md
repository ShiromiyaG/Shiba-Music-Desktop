# Shiba Music (Qt 6 + C++)

Player Navidrome/Subsonic nativo em Qt, com UI moderna (Qt Quick Controls 2), fila, scrobble e busca.

## Build

```bash
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=C:\Qt\6.9.3\mingw_64\lib\cmake ..
cmake --build . -j
./shibamusic
```
qt-cmake -G Ninja ..



```
H:
cd H:\ShibaMusicCPP
mkdir build
cd build
qt-cmake -G Ninja ..
C:\Qt\Tools\Ninja\ninja.exe
```
```
"C:\Qt\6.9.3\mingw_64\bin\windeployqt.exe" H:\ShibaMusicCPP\build\shibamusic.exe
```


Requisitos: Qt 6.5+ (Quick, Network, Multimedia), CMake 3.21+.
