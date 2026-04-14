#!/bin/bash
# Script to fix missing gradle-wrapper.jar

set -e

cd android

# Download gradle-wrapper.jar from Gradle's official distribution
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Downloading gradle-wrapper.jar..."
    GRADLE_VERSION="8.3"
    # Download from Gradle's official distribution
    curl -L -o /tmp/gradle-${GRADLE_VERSION}-bin.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
    unzip -q /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /tmp
    cp /tmp/gradle-${GRADLE_VERSION}/lib/gradle-wrapper-${GRADLE_VERSION}.jar gradle/wrapper/gradle-wrapper.jar
    rm -rf /tmp/gradle-${GRADLE_VERSION} /tmp/gradle-${GRADLE_VERSION}-bin.zip
fi

echo "Gradle wrapper fixed successfully"
