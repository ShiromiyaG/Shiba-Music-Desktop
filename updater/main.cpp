#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
    int argc;
    wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    
    if (argc < 4) {
        MessageBoxW(0, L"Usage: updater.exe zipPath appDir exeName", L"Error", 0);
        return 1;
    }
    
    wchar_t* zip = argv[1];
    wchar_t* app = argv[2];
    wchar_t* exe = argv[3];
    
    Sleep(2000);
    
    wchar_t temp[260];
    GetTempPathW(260, temp);
    
    wchar_t script[260];
    lstrcpyW(script, temp);
    lstrcatW(script, L"update.ps1");
    
    HANDLE f = CreateFileW(script, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0);
    if (f == INVALID_HANDLE_VALUE) {
        MessageBoxW(0, L"Cannot create script", L"Error", 0);
        return 1;
    }
    
    char buf[1024];
    DWORD w;
    
    wsprintfA(buf, "Sleep 2\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    wsprintfA(buf, "$zip='%ls'\r\n", zip); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    wsprintfA(buf, "$app='%ls'\r\n", app); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    wsprintfA(buf, "$tmp='%lsupdate'\r\n", temp); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "New-Item -ItemType Directory -Path $app -Force | Out-Null\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "$ErrorActionPreference='Stop'\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "Expand-Archive -Path $zip -DestinationPath $tmp -Force\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "$entries=@(Get-ChildItem -LiteralPath $tmp)\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "if($entries.Count -eq 1 -and $entries[0].PSIsContainer){$srcPath=$entries[0].FullName}else{$srcPath=$tmp}\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "robocopy \"$srcPath\" \"$app\" /MIR /R:2 /W:2 /NFL /NDL /NJH /NJS /NP | Out-Null\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "$code=$LASTEXITCODE\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "if($code -ge 8){throw $code}\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "rm $tmp -r -force\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "rm $zip -force\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    wsprintfA(buf, "Start-Process \"$app\\%ls\"\r\n", exe); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    lstrcpyA(buf, "rm $PSCommandPath\r\n"); WriteFile(f, buf, lstrlenA(buf), &w, 0);
    
    CloseHandle(f);
    
    wchar_t cmd[520];
    lstrcpyW(cmd, L"powershell -ep bypass -w hidden -f \"");
    lstrcatW(cmd, script);
    lstrcatW(cmd, L"\"");
    
    STARTUPINFOW si = {sizeof(si)};
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    PROCESS_INFORMATION pi;
    
    CreateProcessW(0, cmd, 0, 0, 0, CREATE_NO_WINDOW, 0, 0, &si, &pi);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    
    LocalFree(argv);
    return 0;
}
