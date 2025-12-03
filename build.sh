#!/bin/bash

# Clone Flutter if needed
if [ ! -d flutter ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Setup Flutter
export PATH="$PATH:$PWD/flutter/bin"
flutter config --no-analytics
flutter doctor

# Build with all environment variables
flutter build web --release \
  --dart-define=GROQ_API_KEY=$GROQ_API_KEY \
  --dart-define=API_KEY_1=$API_KEY_1 \
  --dart-define=API_KEY_2=$API_KEY_2 \
  --dart-define=API_KEY_3=$API_KEY_3 \
  --dart-define=API_KEY_4=$API_KEY_4 \
  --dart-define=API_KEY_5=$API_KEY_5 \
  --dart-define=API_KEY_6=$API_KEY_6 \
  --dart-define=API_KEY_7=$API_KEY_7 \
  --dart-define=API_KEY_8=$API_KEY_8 \
  --dart-define=GEMINI_API=$GEMINI_API \
  --dart-define=COHERE_API_KEY=$COHERE_API_KEY \
  --dart-define=LINKEDIN_JOB_API_KEY=$LINKEDIN_JOB_API_KEY
