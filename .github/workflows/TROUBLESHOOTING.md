# 🔧 Troubleshooting - Workflows

## Common Problems and Solutions

### 1. Tag was not created automatically

**Symptom:** I pushed `version.txt` but no tag appeared.

**Possible causes:**

1. **Wrong branch**
   ```bash
   # Check current branch
   git branch --show-current
   ```
   **Solution:** The workflow only works on `main` or `master`. Merge or push to one of these branches.

2. **Tag already exists**
   ```bash
   # View all tags
   git tag
   ```
   **Solution:** The workflow doesn't recreate tags. Use a different version.

3. **Invalid version format**
   ```bash
   # Check content
   cat version.txt
   ```
   **Solution:** Must be exactly `X.Y.Z` (ex: `1.0.1`), with no spaces or extra line breaks.

### 2. Build failed

**Symptom:** The tag was created but the build failed.

**How to investigate:**
1. Visit: `https://github.com/ShiromiyaG/Shiba-Music-Desktop/actions`
2. Click on the failed workflow
3. View the logs of the step that failed

**Common problems:**

#### libmpv not found
```
CMake Error: libmpv not found
```
**Solution:** Add libmpv to the repository or modify the workflow to download it:
```yaml
- name: Download libmpv
  run: |
    # Add step to download libmpv
```

#### C++ compilation error
```
error: 'APP_VERSION' was not declared
```
**Solution:** Ensure that `CMakeLists.txt` defines the macro correctly:
```cmake
target_compile_definitions(shibamusic PRIVATE APP_VERSION="${APP_VERSION}")
```

#### Qt not found
```
CMake Error: Qt6 not found
```
**Solution:** Check Qt version in the workflow (`QT_VERSION: '6.9.3'`)

### 3. Release was not created

**Symptom:** Build passed but there's no release.

**Check:**
```bash
# View releases
gh release list
```

**Possible causes:**

1. **Workflow permissions**
   - Go to: `Settings` → `Actions` → `General`
   - In "Workflow permissions", select: "Read and write permissions"
   - Check: "Allow GitHub Actions to create and approve pull requests"

2. **Expired token**
   - The workflow uses `GITHUB_TOKEN` automatically
   - If customized, verify the token is valid

### 4. Version doesn't appear in app

**Symptom:** App compiles but shows wrong or empty version.

**Check:**

1. **AppInfo.h included?**
   ```cpp
   #include "core/AppInfo.h"
   ```

2. **Registered in QML?**
   ```cpp
   engine.rootContext()->setContextProperty("appInfo", &appInfo);
   ```

3. **Macro defined?**
   ```cmake
   target_compile_definitions(shibamusic PRIVATE APP_VERSION="${APP_VERSION}")
   ```

4. **QML using correctly?**
   ```qml
   Label {
       text: "Version " + appInfo.version
   }
   ```

### 5. Workflow is not being triggered

**Symptom:** I pushed but nothing happened.

**Check:**

1. **Correct file?**
   ```bash
   ls -la .github/workflows/
   ```
   Should contain: `release.yml`

2. **Correct path in trigger?**
   ```yaml
   paths:
     - 'version.txt'  # Must be exactly this name
   ```

3. **Workflows enabled?**
   - Go to: `Actions` tab on GitHub
   - Check if workflows are enabled

### 6. PowerShell script doesn't work

**Symptom:** `.\bump-version.ps1` gives an error.

**Common problems:**

#### Execution Policy
```
cannot be loaded because running scripts is disabled
```
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Git not found
```
'git' is not recognized
```
**Solution:** Install Git or add it to PATH

#### Invalid version
```
Error: Version must be in format X.Y.Z
```
**Solution:** Use correct format: `.\bump-version.ps1 1.0.1`

## 📊 How to monitor progress

### Via GitHub Web
```
https://github.com/ShiromiyaG/Shiba-Music-Desktop/actions
```

### Via GitHub CLI
```bash
# Install GitHub CLI
winget install GitHub.cli

# View workflows
gh workflow list

# View recent runs
gh run list

# View logs of a specific run
gh run view <run-id>
```

## 🆘 Still having problems?

1. **Check the full logs** in GitHub Actions
2. **Compare with a successful workflow** from earlier
3. **Test locally** before pushing:
   ```bash
   # Local build to verify
   cmake -B build -G Ninja
   cmake --build build
   ```

## 📝 Example of Successful Workflow

```
✓ release.yml
  Job: create-release
    └─ Read version: 1.0.1 ✓
    └─ Check if tag exists: false ✓
    └─ Create tag: v1.0.1 ✓
    └─ Push tag ✓
  
  Job: build-windows
    └─ Checkout code ✓
    └─ Install Qt ✓
    └─ Build project ✓
    └─ Deploy dependencies ✓
    └─ Create archive ✓
    └─ Create release ✓

✓ Release v1.0.1 published!
  └─ ShibaMusic-Windows-x64.zip (45MB)
```

## 🔍 Useful logs for debugging

```yaml
# Add debug to workflow
- name: Debug info
  run: |
    echo "Current branch: $(git branch --show-current)"
    echo "Version file content: $(cat version.txt)"
    echo "Existing tags:"
    git tag
    echo "Last commit:"
    git log -1 --oneline
```
