#!/bin/bash
# Script to setup complete Gradle wrapper for Flutter Android project

set -e

cd android

echo "Setting up Gradle wrapper..."

# Initialize gradle wrapper if it doesn't exist
if [ ! -f "gradlew" ]; then
    echo "Gradle wrapper not found, creating..."
    # Use gradle command if available, otherwise download manually
    if command -v gradle &> /dev/null; then
        gradle wrapper --gradle-version 8.3
    else
        echo "Gradle not installed, downloading wrapper files manually..."
        # Download gradle-wrapper.jar directly
        curl -L -o gradle/wrapper/gradle-wrapper.jar \
            "https://github.com/gradle/gradle/raw/v8.3.0/gradle/wrapper/gradle-wrapper.jar"

        # Download gradlew script
        curl -L -o gradlew \
            "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradlew"
        chmod +x gradlew

        # Download gradlew.bat for Windows
        curl -L -o gradlew.bat \
            "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradlew.bat"
    fi
fi

echo "Gradle wrapper setup completed"
