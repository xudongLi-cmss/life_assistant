#!/bin/bash
# Script to fix missing gradle-wrapper.jar

set -e

cd android

# Download gradle-wrapper.jar if it doesn't exist
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Downloading gradle-wrapper.jar..."

    # Try multiple sources for gradle-wrapper.jar
    if curl -fL --connect-timeout 30 --max-time 60 \
        -o gradle/wrapper/gradle-wrapper.jar \
        "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradle/wrapper/gradle-wrapper.jar"; then
        echo "Downloaded from GitHub successfully"
    elif wget -q -O gradle/wrapper/gradle-wrapper.jar \
        "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradle/wrapper/gradle-wrapper.jar" 2>/dev/null; then
        echo "Downloaded using wget successfully"
    else
        echo "ERROR: Failed to download gradle-wrapper.jar from all sources"
        echo "Please check your internet connection or manually add the file"
        exit 1
    fi
fi

# Make gradlew executable
chmod +x gradlew 2>/dev/null || true

echo "Gradle wrapper setup completed successfully"
