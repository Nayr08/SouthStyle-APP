#!/bin/bash

# Install Flutter
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable
export PATH="$PATH:$PWD/flutter/bin"

# Install dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web
echo "Building Flutter web..."
flutter build web --release

# Move build output to root for Vercel
echo "Build complete!"
