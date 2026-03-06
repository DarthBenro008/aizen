## [Task 1] Static Info.plist migration

- Created aizen/Info.plist with Sparkle keys (SUFeedURL, SUPublicEDKey, SUEnableAutomaticChecks)
- pbxproj: GENERATE_INFOPLIST_FILE=NO, INFOPLIST_FILE=aizen/Info.plist for both Debug+Release of aizen target
- Removed INFOPLIST_KEY_LSUIElement and INFOPLIST_KEY_NSHumanReadableCopyright from aizen target (now in static plist)
- Widget target (DD35CF282F538CD400FC8C7E and DD35CF292F538CD400FC8C7E) untouched - kept GENERATE_INFOPLIST_FILE=YES
- Build verified: PASS - xcodebuild build -scheme aizen -configuration Debug succeeded
- Validation: plutil -lint aizen/Info.plist returned OK
- Note: Build warning about Info.plist in Copy Bundle Resources is expected and harmless
- All build settings correctly migrated: LSUIElement and NSHumanReadableCopyright now only in static plist, not build settings

## [Task 2] Sparkle SPM dependency
- Added XCRemoteSwiftPackageReference for https://github.com/sparkle-project/Sparkle (upToNextMajorVersion 2.0.0)
- Added XCSwiftPackageProductDependency for Sparkle product
- Linked to aizen target only (packageProductDependencies)
- Added to aizen Frameworks build phase
- Widget target untouched
- Package resolved: PASS
- Build verified: PASS
- Sparkle.framework in app bundle: YES

## [Task 4] UpdaterService created
- Created aizen/Services/UpdaterService.swift with CheckForUpdatesViewModel: ObservableObject
- Uses Combine KVO bridge for canCheckForUpdates
- Only file in project importing Combine
- Build verified: PASS ✓

## [Task 7] GitHub Actions release workflow
- Created .github/workflows/release.yml (tag-triggered, macos-15 runner)
- Created ExportOptions.plist for Developer ID distribution (Team ID: 7BRH45Z4A8)
- Created docs/appcast.xml placeholder (valid RSS/XML)
- YAML validation: PASS (ruby -ryaml)
- Plist validation: PASS (plutil -lint)
- XML validation: PASS (python3 xml.etree.ElementTree)
- Key workflow steps: cert import, EdDSA key import, version extraction from tag, archive, export, ZIP, EdDSA sign, notarize, appcast update, commit appcast, GitHub Release
- Workflow secrets required: APPLE_CERTIFICATE_P12, APPLE_CERTIFICATE_PASSWORD, SPARKLE_PRIVATE_KEY, APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD
- Appcast will be auto-generated with download URL, file size, pubDate, and EdDSA signature on each release
