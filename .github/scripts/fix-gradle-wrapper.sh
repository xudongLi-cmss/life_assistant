#!/bin/bash
# Script to fix missing gradle-wrapper.jar

set -e

cd android

# Download gradle-wrapper.jar if it doesn't exist
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Downloading gradle-wrapper.jar..."
    # Download directly from Gradle's GitHub releases
    curl -L -o gradle/wrapper/gradle-wrapper.jar \
        "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradle/wrapper/gradle-wrapper.jar"
fi

echo "Gradle wrapper fixed successfully"
