#!/usr/bin/env bash

set -e -o pipefail

xcodebuild -version

xcodebuild \
    -workspace "$FRAMEWORK_NAME.xcworkspace" \
    -scheme "$FRAMEWORK_NAME macOS" \
    ONLY_ACTIVE_ARCH=YES \
    test | xcpretty

xcodebuild \
    -workspace "$FRAMEWORK_NAME.xcworkspace" \
    -scheme "$FRAMEWORK_NAME iOS" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=iPhone 6,OS=10.1" \
    ONLY_ACTIVE_ARCH=NO \
    test | xcpretty

xcodebuild \
    -workspace "$FRAMEWORK_NAME.xcworkspace" \
    -scheme "$FRAMEWORK_NAME tvOS" \
    -sdk appletvsimulator \
    -destination "platform=tvOS Simulator,name=Apple TV 1080p" \
    ONLY_ACTIVE_ARCH=NO \
    test | xcpretty

pod lib lint --quick
