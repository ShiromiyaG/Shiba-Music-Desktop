# Creating a Release

## 🚀 Automatic Process (Recommended)

### Using the script:

```bash
.\bump-version.ps1 1.0.1
```

**What happens:**
1. ✅ Updates `version.txt`
2. ✅ Creates commit automatically
3. ✅ Asks if you want to push
4. ✅ When you push, GitHub Actions:
   - Creates the tag `v1.0.1` automatically
   - Compiles the project
   - Creates a release with the executable

**No manual tagging required!** 🎉

### Manually:

```bash
# 1. Update the version
echo "1.0.1" > version.txt

# 2. Commit and push
git add version.txt
git commit -m "Bump version to 1.0.1"
git push
```

**Done!** GitHub Actions handles the rest automatically.

## 📋 What Happens Automatically

When you push `version.txt`:

1. **"Auto Version Tag" Workflow** is triggered
   - Reads the version from `version.txt`
   - Creates tag `v1.0.1` automatically
   - Pushes the tag

2. **"Build and Release" Workflow** is triggered by the tag
   - Compiles the project on Windows
   - Packages with Qt and dependencies
   - Creates a release on GitHub
   - Attaches `ShibaMusic-Windows-x64.zip`

## ⏱️ Estimated Time

- **Tag creation**: ~30 seconds
- **Full build**: ~5-10 minutes
- **Release available**: Shortly after build completes

## Versioning Structure

Use semantic versioning (SemVer):
- **MAJOR.MINOR.PATCH** (ex: 1.2.3)
- **MAJOR**: Incompatible API changes
- **MINOR**: New backwards-compatible features
- **PATCH**: Bug fixes

## Notes

- The Discord Application ID was removed from the settings interface for security
- It remains functional internally in compiled code
- Releases are created automatically by GitHub Actions
- The executable includes all necessary dependencies (Qt, MinGW, libmpv)
