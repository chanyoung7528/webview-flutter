#!/bin/bash

# Android 에뮬레이터 실행 스크립트

echo "🚀 Android 에뮬레이터 실행 중..."

# 에뮬레이터 목록 확인
echo "📱 사용 가능한 에뮬레이터 목록:"
emulator -list-avds

# 첫 번째 에뮬레이터 실행 (또는 특정 에뮬레이터 이름 지정)
EMULATOR_NAME=$(emulator -list-avds | head -n 1)

if [ -z "$EMULATOR_NAME" ]; then
    echo "❌ 사용 가능한 에뮬레이터가 없습니다."
    echo "Android Studio에서 에뮬레이터를 생성해주세요."
    exit 1
fi

echo "✅ 에뮬레이터 실행: $EMULATOR_NAME"
emulator -avd "$EMULATOR_NAME" > /dev/null 2>&1 &

# 에뮬레이터가 부팅될 때까지 대기
echo "⏳ 에뮬레이터 부팅 대기 중..."
adb wait-for-device

# 부팅 완료까지 추가 대기
echo "⏳ 부팅 완료 대기 중..."
sleep 10

# Flutter 디바이스 확인
echo "🔍 Flutter 디바이스 확인 중..."
flutter devices

# Flutter 앱 실행
echo "🎯 Flutter 앱 실행 중..."
flutter run

