#!/bin/bash
# Script to fix Android project using Flutter's built-in tools

set -e

echo "=== Attempting to fix Android project structure ==="

# Backup current Android directory
if [ -d "android_backup" ]; then
    rm -rf android_backup
fi
cp -r android android_backup
echo "✓ Backed up android directory to android_backup"

# Get the current Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "Flutter version: $FLUTTER_VERSION"

# Try to fix the Android project using Flutter
echo "Running flutter create to regenerate Android project..."
flutter create --org com.example --project-name life_assistant . --android-language kotlin

echo "✓ Android project regenerated"
echo "=== Note: Any custom Android configurations may need to be restored from android_backup ==="
