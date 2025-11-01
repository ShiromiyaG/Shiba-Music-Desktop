# Integração do Updater

## Fluxo de Atualização

```
┌─────────────────────────────────────────────────────────────┐
│                      Shiba Music App                        │
│                                                             │
│  1. UpdateChecker verifica GitHub releases a cada 3s       │
│  2. Compara versão atual (version.txt) com tag_name        │
│  3. Se nova versão disponível → exibe UpdateDialog         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Usuário clica "Download & Install"
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              UpdateChecker::downloadAndInstall()            │
│                                                             │
│  1. Baixa o ZIP do GitHub release                          │
│  2. Salva em %TEMP%\ShibaMusic-Update.zip                  │
│  3. Chama installUpdate(zipPath)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│             UpdateChecker::installUpdate()                  │
│                                                             │
│  1. Verifica se updater.exe existe no appDir               │
│  2. Inicia: updater.exe <zip> <appDir> shibamusic.exe      │
│  3. Fecha o Shiba Music (QCoreApplication::quit())         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      updater.exe                            │
│                                                             │
│  1. Sleep(2000) - aguarda app fechar                       │
│  2. Cria script PowerShell em %TEMP%\update.ps1            │
│  3. Script extrai ZIP → copia arquivos → limpa temp        │
│  4. Script reinicia shibamusic.exe                         │
│  5. Script se auto-deleta                                  │
└─────────────────────────────────────────────────────────────┘
```

## Arquivos Envolvidos

### UpdateChecker.cpp (linhas 207-243)
```cpp
void UpdateChecker::installUpdate(const QString &zipPath) {
    QString appDir = QCoreApplication::applicationDirPath();
    QString updaterPath = appDir + "/updater.exe";
    
    if (!QFile::exists(updaterPath)) {
        emit downloadFailed("Updater executable not found");
        return;
    }
    
    QStringList args;
    args << zipPath << appDir << "shibamusic.exe";
    
    if (QProcess::startDetached(updaterPath, args)) {
        QCoreApplication::quit();
    }
}
```

### updater/main.cpp (67 linhas)
- Recebe: `updater.exe <zipPath> <appDir> <exeName>`
- Cria script PowerShell para:
  - Extrair ZIP
  - Copiar arquivos
  - Limpar temporários
  - Reiniciar aplicação

## Testando Localmente

```bash
# 1. Criar um ZIP fake de update
Compress-Archive -Path build/* -DestinationPath test-update.zip

# 2. Testar updater manualmente
cd build
.\updater.exe "C:\path\to\test-update.zip" "C:\path\to\build" "shibamusic.exe"
```

## Build

O updater.exe é copiado automaticamente para build/ durante a compilação:

```cmake
# CMakeLists.txt
if(EXISTS "${CMAKE_SOURCE_DIR}/updater/updater.exe")
    add_custom_command(TARGET shibamusic POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/updater/updater.exe"
        "$<TARGET_FILE_DIR:shibamusic>/updater.exe"
    )
endif()
```

## Estrutura de Release no GitHub

Para o updater funcionar, o release precisa:

1. **Tag**: `v1.0.16` (ou similar)
2. **Asset**: `ShibaMusic-Windows-x64-v1.0.16.zip`
3. **Conteúdo do ZIP**:
   ```
   ShibaMusic-Windows-x64-v1.0.16/
   ├── shibamusic.exe
   ├── updater.exe
   ├── libmpv-2.dll
   └── ... (outras DLLs Qt)
   ```

## Correções Aplicadas

✅ **Estado de download travado**: Resetado `m_isDownloading` em todos os erros
✅ **Binding loop QML**: Renomeado propriedade para `checker`
✅ **Update na tela de login**: Só abre após `api.authenticated`
✅ **Updater separado**: Executável standalone (52KB) sem dependências Qt
✅ **Logs de debug**: Adicionados para facilitar diagnóstico

## Vantagens do Updater Separado

- ✅ Pequeno (52KB vs >1MB se usasse Qt)
- ✅ Pode substituir o executável principal sem conflitos
- ✅ Usa apenas Windows API nativa
- ✅ Auto-deleta o script após execução
- ✅ Tratamento robusto de erros
