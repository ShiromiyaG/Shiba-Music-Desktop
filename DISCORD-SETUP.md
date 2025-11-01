# 🎮 Discord Rich Presence Setup

This guide explains how to create your own Discord Application for Rich Presence integration.

## Why You Need This

Discord Rich Presence requires a Discord Application ID. Each project/user should have their own Application ID for security and proper attribution.

## Creating Your Discord Application

### Step 1: Access Discord Developer Portal

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Log in with your Discord account

### Step 2: Create New Application

1. Click the **"New Application"** button (top right)
2. Enter a name for your application (e.g., "Shiba Music")
3. Accept the Terms of Service
4. Click **"Create"**

### Step 3: Configure Application

1. On the **General Information** page:
   - Copy the **Application ID** (you'll need this later)
   - Optionally upload an icon for your application
   - Add a description

2. Optional - **Rich Presence** tab:
   - Upload cover art images
   - Configure other Rich Presence settings

### Step 4: Save Your Application ID

Copy your **Application ID** from the General Information page.

Example format: `1234567890123456789`

---

## Using Your Application ID

### For Development (Local)

#### Windows (PowerShell):

```powershell
# Temporary (current session)
$env:DISCORD_CLIENT_ID = "YOUR_APPLICATION_ID_HERE"

# Permanent (System Settings)
# 1. Right-click "This PC" → Properties
# 2. Advanced system settings → Environment Variables
# 3. New User Variable:
#    Name: DISCORD_CLIENT_ID
#    Value: YOUR_APPLICATION_ID_HERE
```

#### Linux/macOS:

```bash
# Temporary (current session)
export DISCORD_CLIENT_ID="YOUR_APPLICATION_ID_HERE"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export DISCORD_CLIENT_ID="YOUR_APPLICATION_ID_HERE"' >> ~/.bashrc
source ~/.bashrc
```

### For GitHub Actions (Repository Owner)

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `DISCORD_CLIENT_ID`
5. Value: Your Application ID
6. Click **"Add secret"**

---

## Testing Rich Presence

1. **Set the environment variable** with your Application ID
2. **Build and run** the application:
   ```bash
   cmake -B build -G Ninja
   cmake --build build
   ./build/shibamusic.exe
   ```
3. **Play some music** in the app
4. **Check Discord** - Your status should show:
   - Your custom application name
   - Currently playing song
   - Artist and album info

---

## Customizing Rich Presence

### Adding Cover Art

1. Go to your Discord Application page
2. Click **Rich Presence** → **Art Assets**
3. Upload images with descriptive names (e.g., "cover", "logo")
4. These can be referenced in the code

### Application Details

Update these in the Discord Developer Portal:
- **Name**: How your app appears in Discord
- **Icon**: Small icon next to your status
- **Description**: What your app does

---

## Security Best Practices

⚠️ **Important Security Notes:**

1. **Never commit your Application ID to public repositories**
   - Always use environment variables
   - Use GitHub Secrets for CI/CD

2. **Keep your Application ID private**
   - Treat it like a password
   - Don't share it publicly

3. **One ID per project**
   - Each fork should have its own Application ID
   - Don't reuse IDs from other projects

4. **Monitor usage**
   - Check Discord Developer Portal regularly
   - Watch for suspicious activity

---

## Troubleshooting

### Rich Presence not showing

1. **Check Discord is running**
   - Discord desktop app must be running
   - Web version doesn't support Rich Presence

2. **Verify environment variable**
   ```powershell
   # Windows
   echo $env:DISCORD_CLIENT_ID
   
   # Linux/macOS
   echo $DISCORD_CLIENT_ID
   ```

3. **Check application logs**
   - Look for: "Discord Client ID not set" message
   - If present, environment variable is not set correctly

4. **Restart the application**
   - Close and reopen Shiba Music
   - Changes to environment variables require restart

### "Invalid Client ID" error

1. **Double-check the ID**
   - Must be exactly as shown in Discord Developer Portal
   - No spaces or extra characters

2. **Verify Application exists**
   - Log into Discord Developer Portal
   - Ensure your application still exists

3. **Check Application ID format**
   - Should be 18-19 digits
   - Example: `1234567890123456789`

### Rich Presence shows wrong app name

1. **Check Application name** in Discord Developer Portal
2. **Update if needed** - changes take effect immediately
3. **Restart Discord** to see changes

---

## FAQs

### Do I need to pay for a Discord Application?

**No**, Discord Applications are completely free to create and use.

### Can I change the Application name later?

**Yes**, you can change the name anytime in the Discord Developer Portal.

### Will this work for other users?

**Yes**, once you set up the Application ID in GitHub Secrets, all builds will use it.

### What if I delete my Discord Application?

You'll need to create a new one and update the Application ID in:
- Local environment variables
- GitHub repository secrets

### Can I use someone else's Application ID?

**No**, you should create your own for security and proper attribution.

---

## Additional Resources

- 📖 [Discord Developer Documentation](https://discord.com/developers/docs/intro)
- 📖 [Rich Presence Documentation](https://discord.com/developers/docs/rich-presence/how-to)
- 🔐 [GitHub Secrets Setup Guide](.github/workflows/SECRETS-SETUP.md)

---

**Need more help?** Open an issue on GitHub or check the [Troubleshooting Guide](.github/workflows/TROUBLESHOOTING.md)
