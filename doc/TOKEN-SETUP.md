# 🔐 GitHub Personal Access Token Setup

This guide shows how to create a Personal Access Token (PAT) for the release workflow.

## ⚠️ REQUIRED - Workflow will fail without this!

**Error you're seeing?**
```
remote: Write access to repository not granted.
fatal: unable to access 'https://github.com/...': error: 403
```

**Solution:** Follow the steps below to create and add a Personal Access Token.

---

## 🚀 Quick Start (5 minutes)

1. **Create token:** [Click here](https://github.com/settings/tokens/new) → Select `repo` scope → Generate
2. **Copy token:** Save it somewhere (you won't see it again!)
3. **Add to repo:** Repository Settings → Secrets → Actions → New secret
4. **Name:** `RELEASE_TOKEN`
5. **Value:** Paste your token
6. **Done!** Re-run the workflow

---

## Step-by-Step Instructions

### Step 1: Create Personal Access Token

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens/new)
2. Or: Click your profile → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token

### Step 2: Configure Token

Fill in the following:

**Note:** Enter a descriptive name like "Shiba Music Release Token"

**Expiration:** Choose your preference (recommended: 90 days or No expiration)

**Select scopes:**
- ✅ `repo` (Full control of private repositories)
  - This includes: repo:status, repo_deployment, public_repo, repo:invite

**IMPORTANT:**
- ✅ Must have `repo` scope
- ✅ This allows creating tags and releases

### Step 3: Generate and Copy Token

1. Scroll to bottom and click **"Generate token"**
2. **COPY THE TOKEN NOW** - You won't be able to see it again!
3. Store it safely (you'll need it in the next step)

### Step 4: Add Token to Repository

1. Go to your repository on GitHub
2. Click `Settings` → `Secrets and variables` → `Actions`
3. Click **"New repository secret"**
4. Name: `RELEASE_TOKEN`
5. Value: Paste your Personal Access Token
6. Click **"Add secret"**

### Step 5: Verify

After saving, you should see:
- ✅ `RELEASE_TOKEN` appears in the secrets list
- ✅ Value is hidden (shows as `***`)
- ✅ You can update or delete it later if needed

## What This Token Does

### The `RELEASE_TOKEN` with `repo` scope allows:
- ✅ Create and push tags to the repository
- ✅ Create releases
- ✅ Upload release assets (ZIP files)
- ✅ Read repository contents

### Security Note
- 🔒 Token is stored encrypted in GitHub Secrets
- 🔒 Only accessible by workflows you define
- 🔒 Can be revoked anytime from your GitHub settings

## Re-running Failed Workflows

If you just configured permissions:

1. Go to **"Actions"** tab
2. Find the failed workflow run
3. Click on it
4. Click **"Re-run all jobs"** (top right)
5. The workflow should now succeed

## Security Considerations

### Is this safe?

**Yes**, when configured properly:
- ✅ Workflows only run on code in your repository
- ✅ You control what workflows can do
- ✅ GitHub provides audit logs
- ✅ You can review workflow files before they run

### Best Practices

1. **Review workflow files** before enabling write permissions
2. **Only enable for trusted repositories** (your own or well-known projects)
3. **Monitor Actions logs** regularly
4. **Use secrets** for sensitive data (we do this for Discord ID)

### What if I'm worried about security?

You can:
1. Review `.github/workflows/release.yml` to see exactly what it does
2. Only enable write permissions when you need to create a release
3. Disable them again after the release is created
4. Use branch protection rules to prevent unauthorized changes

## Token Management

### Updating the Token

If your token expires or you need to change it:

1. Create a new Personal Access Token (follow Step 1-3 above)
2. Go to repository Settings → Secrets → Actions
3. Click on `RELEASE_TOKEN`
4. Click **"Update secret"**
5. Paste new token value
6. Click **"Update secret"**

### Revoking the Token

If you need to revoke access:

1. Go to [GitHub Settings → Tokens](https://github.com/settings/tokens)
2. Find "Shiba Music Release Token"
3. Click **"Delete"** or **"Revoke"**
4. Create a new token and update the secret (if still needed)

## Common Issues

### "Can't see the token after creating"

**Cause:** GitHub only shows the token once for security.

**Solution:** 
1. Create a new token
2. Copy it immediately
3. Save it in a secure location (password manager recommended)

### "Token doesn't work"

**Cause:** Missing required scope or token expired.

**Solution:**
1. Verify token has `repo` scope
2. Check if token is expired
3. Create new token with correct scope
4. Update repository secret

### "Workflow still fails with 403"

**Cause:** Token not set correctly or wrong secret name.

**Solution:**
1. Verify secret name is exactly `RELEASE_TOKEN` (case-sensitive)
2. Check secret value doesn't have extra spaces
3. Try creating a new token
4. Re-run the workflow

## Testing the Token

To verify your token works, push a version bump:

```bash
# Update version
echo "1.0.0" > version.txt

# Commit and push
git add version.txt
git commit -m "Bump version to 1.0.0"
git push

# Watch the workflow run
# Go to Actions tab and monitor progress
```

If the workflow succeeds:
- ✅ Token is working correctly
- ✅ Tag was created
- ✅ Release was published

## Need More Help?

- 📖 [GitHub Docs: Creating a personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- 📖 [GitHub Docs: Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md)

---

**After configuring permissions, your workflow should work perfectly!** 🎉
