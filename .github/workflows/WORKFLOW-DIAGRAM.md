# 🔄 Automatic Versioning and Release Workflow

## Process Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  Developer                                                           │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 1. Execute script or update manually
                              ▼
                    ╔═══════════════════╗
                    ║  bump-version.ps1 ║
                    ║  or manual edit   ║
                    ╚═══════════════════╝
                              │
                              │ 2. Updates version.txt
                              ▼
                    ╔═══════════════════╗
                    ║   version.txt     ║
                    ║   (ex: 1.0.1)     ║
                    ╚═══════════════════╝
                              │
                              │ 3. git commit + push
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  GitHub (main/master branch)                                        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 4. Detects change in version.txt
                              ▼
                    ╔═══════════════════╗
                    ║   release.yml     ║
                    ║ (Single Workflow) ║
                    ╚═══════════════════╝
                              │
                              │ 5. Reads version and creates tag
                              ▼
                    ╔═══════════════════╗
                    ║   Tag v1.0.1      ║
                    ║   (created auto)  ║
                    ╚═══════════════════╝
                              │
                              │ 6. Same workflow continues
                              ▼
                    ╔═══════════════════╗
                    ║  Build & Deploy   ║
                    ║  (same workflow)  ║
                    ╚═══════════════════╝
                              │
                              │ 7. Installs Qt, compiles project
                              ▼
                    ╔═══════════════════╗
                    ║   Build the EXE   ║
                    ║   + Dependencies  ║
                    ╚═══════════════════╝
                              │
                              │ 8. Packages everything
                              ▼
                    ╔═══════════════════╗
                    ║  ZIP with all     ║
                    ║  ready for use    ║
                    ╚═══════════════════╝
                              │
                              │ 9. Creates release on GitHub
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  GitHub Release v1.0.1                                              │
│  ├─ ShibaMusic-Windows-x64.zip                                      │
│  └─ Release Notes                                                   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 10. Users can download
                              ▼
                    ╔═══════════════════╗
                    ║   Users           ║
                    ║   Downloads       ║
                    ╚═══════════════════╝
```

## 📝 Workflow Summary

| Step | Action | Automatic? | Time |
|-------|------|-------------|-------|
| 1 | Execute `bump-version.ps1 X.Y.Z` | ❌ Manual | 5s |
| 2 | Update `version.txt` | ✅ Script | Instant |
| 3 | Commit + Push | ✅ Script (optional) | 2s |
| 4 | Detect change | ✅ GitHub | Instant |
| 5 | Create tag | ✅ Actions | 30s |
| 6 | Trigger build | ✅ Actions | Instant |
| 7 | Compile project | ✅ Actions | 5-10min |
| 8 | Create ZIP | ✅ Actions | 30s |
| 9 | Publish release | ✅ Actions | 10s |
| **Total** | **From version to release** | **Mostly auto** | **~10-15min** |

## 🎯 Advantages

✅ **Zero manual tags** - GitHub Actions creates automatically  
✅ **Zero manual builds** - Everything done in the cloud  
✅ **Consistency guaranteed** - Always the same process  
✅ **Full traceability** - Each version = commit + tag + release  
✅ **Easy rollback** - Just revert the version.txt commit  

## 🔧 Configuration

Single workflow configured in `.github/workflows/`:
- `release.yml` - Creates tags, builds, and publishes releases (all-in-one)

**No additional configuration needed!** 🎉

## 📚 Useful Commands

```bash
# View all tags
git tag

# View current version
cat version.txt

# View releases
gh release list  # (requires GitHub CLI)

# Monitor workflow
# Visit: https://github.com/ShiromiyaG/Shiba-Music-Desktop/actions
```

## ⚠️ Important Notes

1. **Supported branches**: `main` or `master`
2. **Version format**: Must be `X.Y.Z` (SemVer)
3. **Duplicate tags**: Workflow checks and doesn't recreate existing tags
4. **Dependency**: libmpv must be in repository or downloaded during build
