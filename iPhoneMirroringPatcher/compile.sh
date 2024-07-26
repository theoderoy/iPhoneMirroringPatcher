#!/bin/bash

# Navigate to the direct parent directory of the current script
cd "$(dirname "$0")/.."

# Define the project name and scheme
PROJECT_NAME="iPhoneMirroringPatcher.xcodeproj"
SCHEME_NAME="iPhone Mirroring Patcher"

# Define the build directory
BUILD_DIR="build"

# Clean the previous build
xcodebuild clean -project "$PROJECT_NAME" -scheme "$SCHEME_NAME"

# Build the project
xcodebuild build -project "$PROJECT_NAME" -scheme "$SCHEME_NAME" -configuration Release -derivedDataPath "$BUILD_DIR"

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Build succeeded!"
else
    echo "Build failed!"
    exit 1
fi

# Optionally, you can also copy the executable to a specified directory
EXECUTABLE_PATH="$BUILD_DIR/Build/Products/Release/iPhoneMirroringPatcher"

if [ -f "$EXECUTABLE_PATH" ]; then
    echo "Copying executable to the output directory..."
    cp "$EXECUTABLE_PATH" ./output/
    echo "Executable is available in the output directory."
else
    echo "Executable not found!"
    exit 1
fi
