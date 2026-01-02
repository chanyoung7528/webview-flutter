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

# 이미 실행 중인 에뮬레이터 확인
RUNNING_EMULATOR=$(adb devices | grep "emulator" | awk '{print $1}' | head -n 1)
if [ -n "$RUNNING_EMULATOR" ]; then
    echo "✅ 에뮬레이터가 이미 실행 중입니다: $RUNNING_EMULATOR"
else
    # 성능 최적화 옵션 추가: 하드웨어 가속, 빠른 부팅, GPU 가속
    # -no-boot-anim: 부팅 애니메이션 제거로 빠른 부팅
    # -no-audio: 오디오 비활성화로 성능 향상
    # -gpu host: 호스트 GPU 사용으로 가속
    emulator -avd "$EMULATOR_NAME" \
      -gpu host \
      -no-boot-anim \
      -no-audio \
      > /dev/null 2>&1 &
fi

# 에뮬레이터가 부팅될 때까지 대기
echo "⏳ 에뮬레이터 부팅 대기 중..."
adb wait-for-device

# 에뮬레이터가 완전히 부팅될 때까지 대기 (부팅 완료 신호 대기)
echo "⏳ 에뮬레이터 완전 부팅 대기 중..."
MAX_WAIT=120
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # boot_completed 속성 확인
    BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
    if [ "$BOOT_COMPLETED" = "1" ]; then
        echo "✅ 에뮬레이터 부팅 완료!"
        break
    fi
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
    echo -n "."
done
echo ""

# 추가 안정화 대기
echo "⏳ 안정화 대기 중..."
sleep 5

# ADB 서버 재시작 (연결 문제 해결)
echo "🔄 ADB 연결 확인 중..."
adb kill-server 2>/dev/null
sleep 2
adb start-server 2>/dev/null
sleep 2

# Flutter 디바이스 확인
echo "🔍 Flutter 디바이스 확인 중..."
flutter devices

# Android 디바이스 ID 가져오기 (emulator-로 시작하는 ID 추출)
# "unsupported" 상태도 포함해서 찾기
ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -oE "emulator-[0-9]+" | head -n 1)

# 위 방법이 실패하면 다른 방법 시도
if [ -z "$ANDROID_DEVICE" ]; then
    # android-arm64 또는 unsupported가 포함된 라인에서 emulator ID 찾기
    ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -E "(android-arm64|unsupported)" | grep -oE "emulator-[0-9]+" | head -n 1)
fi

# 마지막 시도: 모든 라인에서 emulator ID 찾기
if [ -z "$ANDROID_DEVICE" ]; then
    ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -oE "emulator-[0-9]+" | head -n 1)
fi

if [ -z "$ANDROID_DEVICE" ]; then
    echo "❌ Android 디바이스를 찾을 수 없습니다."
    echo "📱 현재 연결된 디바이스:"
    flutter devices
    echo ""
    echo "💡 해결 방법:"
    echo "1. 에뮬레이터가 완전히 부팅될 때까지 기다려주세요"
    echo "2. Android Studio에서 에뮬레이터를 직접 실행해보세요"
    echo "3. 'adb devices' 명령어로 연결 상태를 확인해보세요"
    exit 1
fi

echo "✅ Android 디바이스: $ANDROID_DEVICE"

# Flutter 앱 실행
echo "🎯 Flutter 앱 실행 중..."
flutter run -d "$ANDROID_DEVICE"

