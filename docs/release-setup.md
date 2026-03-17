# Release Setup Guide

This document covers the one-time setup required before you can publish signed, notarized releases of aizen with OTA auto-update support.

## Prerequisites

- **Apple Developer Program** membership (for Developer ID signing and notarization)
- **Xcode** with the aizen project open (to access Sparkle tools after adding the SPM dependency)
- **GitHub repository** with Pages enabled (for hosting the appcast)

---

## One-Time Setup

Do this once before your first release.

### Step 1: Generate EdDSA Signing Keys

After adding Sparkle via SPM (handled by the Xcode project), locate the `generate_keys` tool:

```bash
# Find the tool in Xcode's derived data:
find ~/Library/Developer/Xcode/DerivedData/aizen-*/SourcePackages/artifacts -name generate_keys 2>/dev/null

# Run it:
/path/to/generate_keys
```

The tool will output your **public key** and store the **private key** securely in your macOS Keychain:

```
A key has been generated and saved in your keychain. Add the `SUPublicEDKey` key to
the Info.plist of each app:

    <key>SUPublicEDKey</key>
    <string>pfIShU4dEXqPd5ObYNfDBiQWcXozk7estwzTnF9BamQ=</string>
```

### Step 2: Add the Public Key to Info.plist

Open `aizen/Info.plist` and replace `PLACEHOLDER_REPLACE_WITH_ACTUAL_KEY` in the `SUPublicEDKey` entry with your actual public key from Step 1.

### Step 3: Export the Private Key for CI

```bash
/path/to/generate_keys -x /tmp/sparkle-private-key.txt
cat /tmp/sparkle-private-key.txt   # copy this content to your clipboard
rm /tmp/sparkle-private-key.txt    # delete immediately after copying
```

### Step 4: Export Your Developer ID Certificate

1. Open **Keychain Access** → **My Certificates**
2. Find **"Developer ID Application: Your Name (TEAMID)"**
3. Right-click → **Export** → save as `developer-id.p12` with a strong password
4. Base64-encode it for use as a GitHub Secret:
   ```bash
   base64 -i developer-id.p12 | pbcopy   # copies to clipboard
   rm developer-id.p12                    # delete the file
   ```

### Step 5: Get an Apple App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com) → **Sign-In and Security** → **App-Specific Passwords**
2. Generate a new password named **"aizen CI"**
3. Copy the generated password

### Step 6: Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value |
|---|---|
| `SPARKLE_PRIVATE_KEY` | Content of the exported private key file (from Step 3) |
| `APPLE_CERTIFICATE_P12` | Base64-encoded `.p12` certificate (from Step 4) |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `APPLE_ID` | Your Apple ID email address |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID (e.g., `7BRH45Z4A8`) |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from Step 5 |
| `HOMEBREW_TAP_TOKEN` | Fine-grained PAT with `contents: write` on `DarthBenro008/homebrew-tap` |

### Step 7: Create a Fine-Grained PAT for the Homebrew Tap

The release workflow pushes cask formula updates to the `DarthBenro008/homebrew-tap` repo. It needs a PAT with write access:

1. Go to **GitHub Settings** → **Developer settings** → **Fine-grained personal access tokens** → **Generate new token**
2. Scope the token to **only** the `DarthBenro008/homebrew-tap` repository
3. Under **Repository permissions**, set **Contents** to **Read and write**
4. Copy the token and add it as the `HOMEBREW_TAP_TOKEN` secret (Step 6)

### Step 8: Enable GitHub Pages

1. Go to your GitHub repo → **Settings** → **Pages**
2. **Source**: Deploy from a branch
3. **Branch**: `main`, **Folder**: `/docs`
4. Click **Save**

Your appcast will be available at:
```
https://darthbenro008.github.io/aizen/appcast.xml
```

---

## Releasing a New Version

Once setup is complete, releasing is a single command:

```bash
# 1. Make your changes and commit them
git add .
git commit -m "feat: your changes"

# 2. Create and push a version tag — CI triggers automatically
git tag v1.1.0
git push origin v1.1.0
```

The GitHub Actions workflow will automatically:
1. Build and archive the app with Xcode
2. Sign with your Developer ID certificate
3. Notarize with Apple
4. Create a ZIP archive signed with your EdDSA key
5. Create a GitHub Release with the ZIP as an asset
6. Update `docs/appcast.xml` with the new release
7. Push the updated appcast to the `main` branch (served via GitHub Pages)
8. Update the Homebrew cask formula in `DarthBenro008/homebrew-tap` with the new version and SHA256

Existing users will receive an update notification within 24 hours (or immediately when they click **Check for Updates**).
The release workflow publishes the human version as `sparkle:shortVersionString` and a monotonically increasing derived build number as `sparkle:version`, which Sparkle uses for update comparisons.

---

## Notes

- **Auto-updates only work with signed release builds** distributed via GitHub Releases. Development builds from Xcode will not receive auto-updates — this is expected and correct.
- **First release**: Users who built from source won't get auto-updates until they download the first signed release manually. After that, all future updates are automatic.
- **Keep your EdDSA private key secure**. If lost, you cannot sign future updates that existing installs will trust. Back it up in a password manager.
- **Do not delete old GitHub Releases** — the appcast references their download URLs. Deleting a release breaks updates for users on older versions.
