# Instruções de Build com Application ID do Discord

## Build Padrão (sem Application ID)

```bash
H:
cd H:\ShibaMusicCPP
mkdir build
cd build
qt-cmake -G Ninja ..
$env:PATH = "C:\Qt\Tools\Ninja;" + $env:PATH
C:\Qt\Tools\Ninja\ninja.exe
copy ..\libs\mpv\bin\mpv-2.dll .
"C:\Qt\6.9.3\mingw_64\bin\windeployqt.exe" shibamusic.exe
```

## Build com Application ID do Discord

Para compilar com um Application ID do Discord pré-configurado, defina a variável de ambiente `DISCORD_APP_ID` antes de executar o cmake:

```bash
H:
cd H:\ShibaMusicCPP
mkdir build
cd build

# Definir o Application ID do Discord
$env:DISCORD_APP_ID = "SEU_APPLICATION_ID_AQUI"

qt-cmake -G Ninja ..
$env:PATH = "C:\Qt\Tools\Ninja;" + $env:PATH
C:\Qt\Tools\Ninja\ninja.exe
copy ..\libs\mpv\bin\mpv-2.dll .
"C:\Qt\6.9.3\mingw_64\bin\windeployqt.exe" shibamusic.exe
```

Substitua `SEU_APPLICATION_ID_AQUI` pelo seu Application ID do Discord.

## Notas

- O Application ID definido na compilação NÃO ficará visível no executável compilado
- O usuário ainda pode alterar o Application ID manualmente nas configurações do aplicativo
- Se nenhum Application ID for definido na compilação, o campo ficará vazio e o usuário precisará configurá-lo manualmente
