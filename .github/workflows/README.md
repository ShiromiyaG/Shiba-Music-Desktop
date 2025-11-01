# 🚀 GitHub Actions Workflows

Fully automated CI/CD system for Shiba Music.

## 📋 Available Workflows

### 1. version-bump.yml - 🏷️ Auto Version Tag

**Purpose:** Automatically creates tags when `version.txt` is updated.

**Trigger:**
```yaml
on:
  push:
    branches: [main, master]
    paths: ['version.txt']
```

**Process:**
1. ✅ Detects change in `version.txt`
2. ✅ Reads the new version
3. ✅ Checks if tag already exists
4. ✅ Creates tag `v1.0.1` automatically
5. ✅ Pushes the tag

**Usage:**
```bash
# Update version
echo "1.0.1" > version.txt
git commit -am "Bump version to 1.0.1"
git push

# Done! Tag created automatically
```

---

### 2. build-release.yml - 🔨 Build and Release

**Purpose:** Compiles the project and publishes release when a tag is created.

**Trigger:**
```yaml
on:
  push:
    tags: ['v*']
```

**Process:**
1. ✅ Code checkout
2. ✅ Installs Qt 6.9.3 + MinGW
3. ✅ Configures CMake + Ninja
4. ✅ Compiles in Release mode
5. ✅ Packages with windeployqt
6. ✅ Creates ZIP with everything
7. ✅ Publishes release on GitHub

**Artifacts:**
- `ShibaMusic-Windows-x64.zip` - Executable + dependencies

---

## 🎯 How to Use

### Easy Method (Script):

```bash
.\bump-version.ps1 1.0.1
```

This starts the entire process automatically!

### Manual Method:

```bash
# 1. Update version
echo "1.0.1" > version.txt

# 2. Commit and push
git commit -am "Bump version to 1.0.1"
git push

# Done! 🎉
# - Tag created in ~30s
# - Full build in ~10min
# - Release published automatically
```

---

## 📊 Complete Workflow

```
version.txt updated
         ↓
    git push
         ↓
  ┌──────────────────┐
  │ version-bump.yml │
  │  Creates tag     │
  └──────────────────┘
         ↓
    Tag v1.0.1
         ↓
  ┌──────────────────┐
  │build-release.yml │
  │  Compile + Deploy│
  └──────────────────┘
         ↓
  Release v1.0.1 🎉
  (with ZIP attached)
```

---

## ⚙️ Required Configuration

### GitHub Actions Permissions

1. Go to: `Settings` → `Actions` → `General`
2. Under "Workflow permissions":
   - ☑️ Check "Read and write permissions"
   - ☑️ Check "Allow GitHub Actions to create and approve pull requests"

### libmpv

⚠️ **IMPORTANT:** The workflow needs libmpv.

**Option A - Include in repo (recommended):**
```bash
git add -f libs/mpv/
git commit -m "Add libmpv for CI"
git push
```

**Option B - Download during build:**
Modify `build-release.yml` to download libmpv from SourceForge.

---

## 🔧 Environment Variables

| Variable | Value | Description |
|----------|-------|-----------|
| `QT_VERSION` | `6.9.3` | Qt version |
| `GITHUB_TOKEN` | Auto | Access token (automatic) |

---

## 📚 Additional Documentation

- 📖 [Workflow Diagram](./WORKFLOW-DIAGRAM.md)
- 🔧 [Troubleshooting](./TROUBLESHOOTING.md)
- 📝 [Release Instructions](../../RELEASE.md)

---

## 🎉 Advantages

✅ **Zero manual tags** - Fully automatic  
✅ **Consistent build** - Always the same environment  
✅ **Traceability** - Commit → Tag → Release  
✅ **Easy rollback** - Revert version.txt commit  
✅ **Centralized versioning** - Single source (version.txt)  

---

## 📞 Support

Issues? Check [Troubleshooting](./TROUBLESHOOTING.md) or logs at:
```
https://github.com/<user>/<repo>/actions
```
