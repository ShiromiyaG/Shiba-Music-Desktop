# Shiba Music (Qt 6 + C++)

Player Navidrome/Subsonic nativo em Qt, com UI moderna (Qt Quick Controls 2), fila, scrobble e busca.

## Requisitos

- Qt 6.5+ (Quick, Network, Core5Compat)
- CMake 3.21+
- libmpv (para gapless playback)

## Setup do libmpv

1. Execute o script de setup:
```bash
setup_mpv.bat
```

2. Baixe libmpv de: https://sourceforge.net/projects/mpv-player-windows/files/libmpv/

3. Extraia e copie os arquivos conforme instruções do script

Veja `LIBMPV_SETUP.md` para mais detalhes.

## Build

```bash
H:
cd H:\ShibaMusicCPP
mkdir build
cd build
qt-cmake -G Ninja ..
C:\Qt\Tools\Ninja\ninja.exe
copy ..\libs\mpv\bin\mpv-2.dll .
"C:\Qt\6.9.3\mingw_64\bin\windeployqt.exe" shibamusic.exe
```
