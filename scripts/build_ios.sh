#!/usr/bin/env bash
# TowerDash Bricks — iOS Release Build Script
# Run from the project root on a Mac with Xcode + CocoaPods installed.
#
# Usage:
#   chmod +x scripts/build_ios.sh
#   ./scripts/build_ios.sh
#
# Output: build/ios/ipa/TowerDashBricks.ipa

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

BUNDLE_ID="com.towerlab.tower.dash.bricks"
TEAM_ID="NXTLARTUHG"
ARCHIVE_PATH="$PROJECT_ROOT/build/ios/Runner.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/build/ios/ipa"

echo "==> [1/4] Flutter pub get"
flutter pub get

echo "==> [2/4] Clean CocoaPods install"
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd "$PROJECT_ROOT"

echo "==> [3/4] Xcode archive"
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  archive \
  | xcpretty || true

echo "==> [4/4] Export IPA"
mkdir -p "$EXPORT_PATH"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "ios/ExportOptions.plist" \
  -exportPath "$EXPORT_PATH" \
  | xcpretty || true

echo ""
echo "Done. IPA is at: $EXPORT_PATH"
ls -lh "$EXPORT_PATH"/*.ipa 2>/dev/null || echo "(no .ipa found — check xcodebuild output above)"
