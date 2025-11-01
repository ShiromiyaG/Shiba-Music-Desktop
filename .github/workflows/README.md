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

1. Go to: `Settings` → `Actions` → `General`
2. Under "Workflow permissions":
   - ☑️ Check "Read and write permissions"
   - ☑️ Check "Allow GitHub Actions to create and approve pull requests"

### GitHub Secrets

**DISCORD_CLIENT_ID** (Required)

1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret`
3. Name: `DISCORD_CLIENT_ID`
4. Value: Your Discord Application ID
5. Click `Add secret`

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

## 🔧 Environment Variables

| Variable | Value | Description |
|----------|-------|-----------|
| `QT_VERSION` | `6.9.3` | Qt version |
| `DISCORD_CLIENT_ID` | Secret | Discord Application ID (from GitHub Secrets) |
| `GITHUB_TOKEN` | Auto | Access token (automatic) |

---

## 📚 Additional Documentation

- 📖 [Workflow Diagram](./WORKFLOW-DIAGRAM.md)
- 🔐 [Secrets Setup Guide](./SECRETS-SETUP.md)
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
