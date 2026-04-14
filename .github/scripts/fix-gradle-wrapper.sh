#!/bin/bash
# Script to fix missing gradle-wrapper.jar

set -e

echo "=== Starting Gradle wrapper setup ==="

cd android

echo "Current directory: $(pwd)"
echo "Gradle wrapper directory contents:"
ls -la gradle/wrapper/ 2>/dev/null || echo "gradle/wrapper directory does not exist"

# Download gradle-wrapper.jar if it doesn't exist
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "gradle-wrapper.jar not found, downloading..."

    # Try multiple sources for gradle-wrapper.jar
    echo "Attempting to download from GitHub..."
    if curl -fL --connect-timeout 30 --max-time 60 --retry 3 --retry-delay 5 \
        -o gradle/wrapper/gradle-wrapper.jar \
        "https://raw.githubusercontent.com/gradle/gradle/v8.3.0/gradle/wrapper/gradle-wrapper.jar" 2>&1; then
        echo "✓ Downloaded from GitHub successfully"
        file_size=$(stat -c%s gradle/wrapper/gradle-wrapper.jar 2>/dev/null || stat -f%z gradle/wrapper/gradle-wrapper.jar)
        echo "File size: $file_size bytes"
    else
        echo "✗ GitHub download failed"
        echo "Attempting to use Gradle to generate wrapper..."
        if command -v gradle &> /dev/null; then
            gradle wrapper --gradle-version 8.3
        else
            echo "ERROR: Failed to download gradle-wrapper.jar and gradle command not available"
            exit 1
        fi
    fi
else
    echo "gradle-wrapper.jar already exists"
fi

# Verify the file exists and is not empty
if [ -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    file_size=$(stat -c%s gradle/wrapper/gradle-wrapper.jar 2>/dev/null || stat -f%z gradle/wrapper/gradle-wrapper.jar)
    echo "✓ gradle-wrapper.jar exists, size: $file_size bytes"
else
    echo "✗ gradle-wrapper.jar does not exist after setup attempt"
    exit 1
fi

# Make gradlew executable
chmod +x gradlew 2>/dev/null || true

echo "=== Gradle wrapper setup completed ==="
