#!/bin/bash

# Check if at least one framework name is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <framework1> [<framework2> ...]"
  exit 1
fi

set -e

# Variables
WORKSPACE="TheWebSnippet.xcworkspace"
OUTPUT_DIRECTORY="./XCFrameworks"
DERIVED_DATA_PATH="build"

# Clean previous build artifacts
rm -rf "${DERIVED_DATA_PATH}"
rm -rf "${OUTPUT_DIRECTORY}"

# Create output directory
mkdir -p "${OUTPUT_DIRECTORY}"

# Iterate through each framework provided as argument
for SCHEME in "$@"
do
  # Build for iOS devices
  xcodebuild archive \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${DERIVED_DATA_PATH}/${SCHEME}_ios_devices.xcarchive" \
    SKIP_INSTALL=NO \
    # BUILD_LIBRARY_FOR_DISTRIBUTION=YES \

  # Build for iOS simulators
  xcodebuild archive \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${DERIVED_DATA_PATH}/${SCHEME}_ios_simulators.xcarchive" \
    SKIP_INSTALL=NO \
    # BUILD_LIBRARY_FOR_DISTRIBUTION=YES \

  # Create XCFramework
  xcodebuild -create-xcframework \
    -framework "${DERIVED_DATA_PATH}/${SCHEME}_ios_devices.xcarchive/Products/Library/Frameworks/${SCHEME}.framework" \
    -framework "${DERIVED_DATA_PATH}/${SCHEME}_ios_simulators.xcarchive/Products/Library/Frameworks/${SCHEME}.framework" \
    -output "${OUTPUT_DIRECTORY}/${SCHEME}.xcframework"

  echo "XCFramework created for ${SCHEME} at ${OUTPUT_DIRECTORY}/${SCHEME}.xcframework"
done