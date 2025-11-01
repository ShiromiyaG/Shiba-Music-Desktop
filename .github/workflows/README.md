# 🚀 GitHub Actions Workflow

Fully automated CI/CD system for Shiba Music - **Single workflow handles everything!**

## 📋 Workflow: `release.yml`

**Purpose:** Automatically creates tags, builds, and publishes releases when `version.txt` is updated.

**Trigger:**
```yaml
on:
  push:
    branches: [main, master]
    paths: ['version.txt']
```

**Complete Process:**
1. ✅ Detects change in `version.txt`
2. ✅ Reads the new version
3. ✅ Checks if tag already exists
4. ✅ Creates tag `v1.0.1` automatically
5. ✅ Pushes the tag
6. ✅ Installs Qt 6.9.3 + MinGW
7. ✅ Configures CMake + Ninja
8. ✅ Compiles in Release mode
9. ✅ Packages with windeployqt
10. ✅ Creates ZIP with everything
11. ✅ Publishes release on GitHub

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
# Everything happens automatically:
# - Tag created in ~30s
# - Full build in ~10min
# - Release published in ~15min total
```

---

## 📊 Complete Workflow

```
version.txt updated
         ↓
    git push
         ↓
  ┌─────────────────────┐
  │   release.yml       │
  │                     │
  │  1. Create Tag      │
  │  2. Build Project   │
  │  3. Deploy Qt Deps  │
  │  4. Create Archive  │
  │  5. Publish Release │
  └─────────────────────┘
         ↓
  Release v1.0.1 🎉
  (with ZIP attached)
```

---

## ⚙️ Required Configuration

### GitHub Actions Permissions

⚠️ **CRITICAL:** You must configure these permissions for the workflow to work!

1. Go to: `Settings` → `Actions` → `General`
2. Scroll down to **"Workflow permissions"**
3. Select: **"Read and write permissions"** (⚠️ REQUIRED!)
4. Check: **"Allow GitHub Actions to create and approve pull requests"**
5. Click **"Save"**

**Without these permissions, the workflow cannot create tags or releases!**

### GitHub Secrets

**Required Secrets:**

1. **RELEASE_TOKEN** (Required for creating tags and releases)
   - Go to: `Settings` → `Secrets and variables` → `Actions`
   - Click `New repository secret`
   - Name: `RELEASE_TOKEN`
   - Value: Create a [Personal Access Token](https://github.com/settings/tokens/new) with `repo` scope
   - Click `Add secret`

2. **DISCORD_CLIENT_ID** (Required for Discord Rich Presence)
   - Click `New repository secret`
   - Name: `DISCORD_CLIENT_ID`
   - Value: Your Discord Application ID
   - Click `Add secret`

See [Secrets Setup Guide](./SECRETS-SETUP.md) for detailed instructions.

### libmpv

⚠️ **IMPORTANT:** The workflow needs libmpv.

**Option A - Include in repo (recommended):**
```bash
git add -f libs/mpv/
git commit -m "Add libmpv for CI"
git push
```

**Option B - Download during build:**
Modify `release.yml` to download libmpv from SourceForge.

---

## 🔧 Environment Variables & Secrets

| Variable | Value | Description |
|----------|-------|-----------|
| `QT_VERSION` | `6.9.3` | Qt version |
| `DISCORD_CLIENT_ID` | Secret | Discord Application ID (from GitHub Secrets) |
| `RELEASE_TOKEN` | Secret | Personal Access Token for creating releases |

---

## 📚 Additional Documentation

- 🔐 [Token Setup Guide](./TOKEN-SETUP.md) - **Fix 403 errors! REQUIRED!**
- 📖 [Workflow Diagram](./WORKFLOW-DIAGRAM.md)
- 🔐 [Secrets Setup Guide](./SECRETS-SETUP.md) - Discord Client ID
- 🔧 [Troubleshooting](./TROUBLESHOOTING.md)
- 📝 [Release Instructions](../../RELEASE.md)

---

## 🎉 Advantages

✅ **Single workflow** - Everything in one place  
✅ **Zero manual tags** - Fully automatic  
✅ **Consistent build** - Always the same environment  
✅ **Traceability** - Commit → Tag → Release  
✅ **Easy rollback** - Revert version.txt commit  
✅ **Centralized versioning** - Single source (version.txt)  
✅ **Simpler maintenance** - One file to manage  

---

## 📞 Support

Issues? Check [Troubleshooting](./TROUBLESHOOTING.md) or logs at:
```
https://github.com/ShiromiyaG/Shiba-Music-Desktop/actions
```
