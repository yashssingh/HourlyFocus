#!/bin/bash

# Stop on errors
set -e

echo "Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign

echo "Creating Payload directory..."
mkdir -p Payload

echo "Copying app to Payload directory..."
cp -r build/ios/iphoneos/Runner.app Payload/

echo "Zipping into IPA file..."
zip -r HourlyFocus.ipa Payload

echo "Cleaning up temporary files..."
rm -rf Payload

echo "IPA file created successfully at $(pwd)/HourlyFocus.ipa"
echo "You can now share this IPA file with others for sideloading." 