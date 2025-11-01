# 🎮 Discord Rich Presence Setup

This guide explains how Discord integration works in Shiba Music.

---

## 🔐 How Discord Client ID is Handled

The Discord Application ID is **compiled into the executable** during build, making it secure and transparent for users.

### Security Features:

✅ **Hidden from repository** - ID is stored as GitHub Secret
✅ **Compiled into binary** - Users don't need to configure anything
✅ **Not easily extractable** - Embedded as compiled constant
✅ **Encrypted in GitHub** - Secret is encrypted at rest
✅ **Optional override** - Developers can use environment variable

---

## 📋 Setup Instructions

### 1. Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **"New Application"**
3. Name it: "Shiba Music" (or your preferred name)
4. Click **"Create"**

### 2. Get Application ID

1. In your application page, go to **"General Information"**
2. Copy the **"Application ID"** (long number)
3. Example: `1234567890123456789`

### 3. Add to GitHub Secrets

1. Go to your repository on GitHub
2. Click: `Settings` → `Secrets and variables` → `Actions`
3. Click: **"New repository secret"**
4. Fill in:
   - **Name:** `DISCORD_CLIENT_ID`
   - **Value:** Your Application ID (the number you copied)
5. Click: **"Add secret"**

### 4. Configure Rich Presence (Optional)

If you want to customize the Rich Presence display:

1. In Discord Developer Portal, go to **"Rich Presence"** tab
2. Upload images for:
   - **Large Image:** App logo (1024x1024 recommended)
   - **Small Image:** Play/pause icons (256x256)
3. Set image keys (used in code):
   - `shiba_music` - Main app icon
   - `playing` - Playing state icon
   - `paused` - Paused state icon

---

## 🔧 How It Works

### Build Process:

```
1. GitHub Actions starts
   ↓
2. Reads DISCORD_CLIENT_ID secret
   ↓
3. Sets as environment variable
   ↓
4. CMake reads environment variable
   ↓
5. Defines DISCORD_CLIENT_ID preprocessor macro
   ↓
6. C++ code uses compiled constant
   ↓
7. Executable has ID embedded
   ↓
8. Users run app → Discord RPC works automatically
```

### Code Flow:

```cpp
// DiscordRPC.cpp
DiscordRPC::DiscordRPC(QObject *parent) : QObject(parent)
{
    // Priority order:
    // 1. Environment variable (for development)
    QString envId = env.value("DISCORD_CLIENT_ID", "");
    
    // 2. Compiled-in ID (for production)
    QString compiledId = QString(DISCORD_CLIENT_ID);
    
    if (!envId.isEmpty())
        m_clientId = envId;  // Use env var
    else if (!compiledId.isEmpty())
        m_clientId = compiledId;  // Use compiled ID
}
```

---

## 🧪 Testing

### Local Development:

```bash
# Set environment variable
export DISCORD_CLIENT_ID="your_test_app_id"

# Build and run
cmake -B build
cmake --build build
./build/shibamusic
```

### Production Build:

The GitHub Actions workflow automatically uses the secret:

```yaml
- name: Configure CMake
  run: |
    $env:DISCORD_CLIENT_ID = "${{ secrets.DISCORD_CLIENT_ID }}"
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
```

---

## 🔍 Verification

### Check if Discord ID is set:

When you run the app, check the console output:

```
✅ With ID:
Discord: Using compiled-in Client ID
Discord RPC initialized

❌ Without ID:
Discord Client ID not set. Discord Rich Presence disabled.
```

### In Discord:

If working correctly, your Discord profile will show:

```
Playing Shiba Music
🎵 Song Name - Artist Name
on Album Name
```

---

## ❓ FAQ

### Q: Can users see my Discord Application ID?

**A:** Technically yes, if they decompile the binary. However:
- It's just an Application ID, not a secret token
- It can't be used to harm your account
- It only allows showing Rich Presence under your app name
- This is the standard way Discord RPC works

### Q: Why not use environment variable for users?

**A:** Better UX:
- ✅ Works out of the box
- ✅ No configuration needed
- ✅ Consistent experience
- ❌ Asking users to set env vars is bad UX

### Q: Can I have different IDs for dev/prod?

**A:** Yes!
```bash
# Development (local)
export DISCORD_CLIENT_ID="dev_app_id"

# Production (GitHub Actions)
# Uses GitHub Secret automatically
```

### Q: What if I want to disable Discord RPC?

**A:** Don't add the `DISCORD_CLIENT_ID` secret to GitHub. The app will work normally without Discord integration.

---

## 🛡️ Security Best Practices

✅ **DO:**
- Store ID as GitHub Secret
- Use compiled-in ID for releases
- Allow env var override for testing
- Document that ID is in binary

❌ **DON'T:**
- Hardcode ID in source code
- Commit ID to repository
- Share your Application ID publicly (though it's not critical)
- Use same ID for dev and prod (optional, but recommended)

---

## 🔗 Resources

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Rich Presence Documentation](https://discord.com/developers/docs/rich-presence/how-to)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

## ✅ Checklist

- [ ] Created Discord Application
- [ ] Copied Application ID
- [ ] Added `DISCORD_CLIENT_ID` to GitHub Secrets
- [ ] Configured Rich Presence assets (optional)
- [ ] Tested build with Discord integration
- [ ] Verified Rich Presence shows in Discord

**All set!** Your releases will now have Discord Rich Presence built-in. 🎉
