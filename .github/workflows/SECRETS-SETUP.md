# 🔐 GitHub Secrets Setup

This document explains how to configure secrets for the GitHub Actions workflow.

## Required Secrets

### DISCORD_CLIENT_ID

The Discord Application ID for Rich Presence integration.

**Setup Instructions:**

1. **Get your Discord Application ID:**
   - Go to [Discord Developer Portal](https://discord.com/developers/applications)
   - Create a new application or select existing one
   - Copy the **Application ID** from the General Information page

2. **Add to GitHub Secrets:**
   - Go to your repository on GitHub
   - Click `Settings` → `Secrets and variables` → `Actions`
   - Click `New repository secret`
   - Name: `DISCORD_CLIENT_ID`
   - Value: Paste your Discord Application ID
   - Click `Add secret`

3. **Verify:**
   - The workflow will automatically use this secret during builds
   - The value will be compiled into the executable
   - Users won't need to configure it

## Local Development

### Windows

To test locally with your own Discord Client ID:

1. **Set environment variable (PowerShell):**
   ```powershell
   $env:DISCORD_CLIENT_ID = "your_client_id_here"
   ```

2. **Set permanently (System Settings):**
   - Right-click `This PC` → `Properties`
   - Click `Advanced system settings`
   - Click `Environment Variables`
   - Under `User variables`, click `New`
   - Variable name: `DISCORD_CLIENT_ID`
   - Variable value: Your Discord Application ID
   - Click `OK` and restart your IDE/terminal

3. **Build the project:**
   ```powershell
   cmake -B build -G Ninja
   cmake --build build
   ```

### Linux/macOS

```bash
# Temporary (current session only)
export DISCORD_CLIENT_ID="your_client_id_here"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export DISCORD_CLIENT_ID="your_client_id_here"' >> ~/.bashrc
source ~/.bashrc
```

## Default Behavior

If `DISCORD_CLIENT_ID` is not set:
- ⚠️ Discord Rich Presence will be **disabled**
- ✅ Application will work normally otherwise
- ℹ️ You must set your own Discord Application ID to use Rich Presence

## Security Notes

⚠️ **Important:**
- Never commit Discord Client IDs directly in the code
- Use environment variables or GitHub Secrets
- The workflow uses GitHub's secret masking to prevent exposure in logs

## Troubleshooting

### Secret not working in Actions

1. **Check secret name:**
   - Must be exactly `DISCORD_CLIENT_ID`
   - Case sensitive

2. **Check secret value:**
   - Must be your Discord Application ID (numbers only)
   - No quotes or extra spaces

3. **Re-run workflow:**
   - Secrets are loaded at workflow start
   - If you just added it, re-run the workflow

### Local build not using custom ID

1. **Verify environment variable:**
   ```powershell
   # Windows
   echo $env:DISCORD_CLIENT_ID
   
   # Linux/macOS
   echo $DISCORD_CLIENT_ID
   ```

2. **Restart IDE/terminal:**
   - Environment variables require a restart to take effect

3. **Clean build:**
   ```powershell
   Remove-Item -Recurse -Force build
   cmake -B build -G Ninja
   cmake --build build
   ```

## Additional Configuration

### Using a different secret name

If you want to use a different secret name, update `.github/workflows/release.yml`:

```yaml
env:
  DISCORD_CLIENT_ID: ${{ secrets.YOUR_SECRET_NAME }}
```

And update the build steps:

```yaml
- name: Build
  run: |
    $env:DISCORD_CLIENT_ID = "${{ secrets.YOUR_SECRET_NAME }}"
    cmake --build build --config Release
```

## For Contributors

If you're contributing to the project and want to test Discord integration:

1. Create your own Discord Application at [Discord Developer Portal](https://discord.com/developers/applications)
2. Use your own Discord Application ID locally
3. Set the `DISCORD_CLIENT_ID` environment variable
4. **Never commit your personal Client ID to the repository**
5. Discord Rich Presence is optional - the app works without it

---

**Need help?** Check the [Troubleshooting Guide](./TROUBLESHOOTING.md)
