#!/bin/bash
set -e

APP_NAME="BestBrowser"
APP_VERSION="$(cat VERSION)"
MIN_MACOS_VERSION="26.0"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME-v$APP_VERSION.dmg"
RELEASES_DIR="releases"

cd "$(dirname "$0")"

echo "=> Building $APP_NAME v$APP_VERSION..."

echo "=> Generating brand assets..."
swift Scripts/generate_brand_assets.swift

swift build -c release

echo "=> Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Resources/BrandingAssets"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

if [ -d "BestBrowser/Assets.xcassets" ]; then
    cp -R BestBrowser/Assets.xcassets "$APP_BUNDLE/Contents/Resources/"
fi

if [ -d "BestBrowser/BrandingAssets" ]; then
    cp -R BestBrowser/BrandingAssets/. "$APP_BUNDLE/Contents/Resources/BrandingAssets/"
fi

ICONSET_DIR="BestBrowser/Assets.xcassets/AppIcon.appiconset"
ICONUTIL_SET="$(mktemp -d)"
if [ -d "$ICONSET_DIR" ]; then
    cp "$ICONSET_DIR/icon_16x16.png" "$ICONUTIL_SET/icon_16x16.png"
    cp "$ICONSET_DIR/icon_16x16@2x.png" "$ICONUTIL_SET/icon_16x16@2x.png"
    cp "$ICONSET_DIR/icon_32x32.png" "$ICONUTIL_SET/icon_32x32.png"
    cp "$ICONSET_DIR/icon_32x32@2x.png" "$ICONUTIL_SET/icon_32x32@2x.png"
    cp "$ICONSET_DIR/icon_128x128.png" "$ICONUTIL_SET/icon_128x128.png"
    cp "$ICONSET_DIR/icon_128x128@2x.png" "$ICONUTIL_SET/icon_128x128@2x.png"
    cp "$ICONSET_DIR/icon_256x256.png" "$ICONUTIL_SET/icon_256x256.png"
    cp "$ICONSET_DIR/icon_256x256@2x.png" "$ICONUTIL_SET/icon_256x256@2x.png"
    cp "$ICONSET_DIR/icon_512x512.png" "$ICONUTIL_SET/icon_512x512.png"
    cp "$ICONSET_DIR/icon_512x512@2x.png" "$ICONUTIL_SET/icon_512x512@2x.png"
    mv "$ICONUTIL_SET" "$ICONUTIL_SET.iconset"
    iconutil -c icns "$ICONUTIL_SET.iconset" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONUTIL_SET.iconset"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.bestbrowser.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>ASWebAuthenticationSessionWebBrowserSupportCapabilities</key>
    <dict>
        <key>IsSupported</key>
        <true/>
        <key>CallbackURLMatchingIsSupported</key>
        <true/>
    </dict>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS_VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>HTML Document</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.html</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

cat > "$APP_BUNDLE/Contents/embedded.provisionprofile" << 'EOF'
EOF
rm -f "$APP_BUNDLE/Contents/embedded.provisionprofile"

echo "=> Creating DMG..."
mkdir -p "$RELEASES_DIR"
rm -f "$RELEASES_DIR/$DMG_NAME"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov -format UDZO \
    "$RELEASES_DIR/$DMG_NAME"

DMG_SIZE=$(du -h "$RELEASES_DIR/$DMG_NAME" | cut -f1)

echo ""
echo "=> Build complete!"
echo "   App: $(pwd)/$APP_BUNDLE"
echo "   DMG: $RELEASES_DIR/$DMG_NAME ($DMG_SIZE)"
echo "   Launch: open $APP_BUNDLE"
