#!/bin/bash

# iOS 시뮬레이터 실행 스크립트

echo "🚀 iOS 시뮬레이터 실행 중..."

# 사용 가능한 시뮬레이터 목록 확인
echo "📱 사용 가능한 시뮬레이터 목록:"
xcrun simctl list devices available | grep iPhone

# 첫 번째 사용 가능한 iPhone 시뮬레이터 찾기 (부팅되지 않은 것 우선)
DEVICE_INFO=$(xcrun simctl list devices available | grep -i "iPhone" | grep -v "unavailable" | head -n 1)

if [ -z "$DEVICE_INFO" ]; then
    echo "❌ 사용 가능한 iPhone 시뮬레이터가 없습니다."
    echo "Xcode에서 시뮬레이터를 생성해주세요."
    exit 1
fi

# 디바이스 ID 추출
DEVICE_ID=$(echo "$DEVICE_INFO" | grep -oE '[A-F0-9-]{36}' | head -n 1)
DEVICE_NAME=$(echo "$DEVICE_INFO" | sed 's/.*(\(.*\))/\1/' | sed 's/).*//')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ 시뮬레이터 ID를 찾을 수 없습니다."
    exit 1
fi

echo "✅ 선택된 시뮬레이터: $DEVICE_NAME ($DEVICE_ID)"

# 시뮬레이터가 이미 실행 중인지 확인
BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted" || echo "")

if [ -z "$BOOT_STATUS" ]; then
    echo "🔄 시뮬레이터 부팅 중..."
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || {
        echo "⚠️  부팅 실패, 이미 실행 중일 수 있습니다."
    }
    
    # Simulator 앱 열기
    open -a Simulator
    
    # 시뮬레이터가 부팅될 때까지 대기
    echo "⏳ 시뮬레이터 부팅 완료 대기 중..."
    while [ -z "$(xcrun simctl list devices | grep "$DEVICE_ID" | grep "Booted")" ]; do
        sleep 2
        echo -n "."
    done
    echo ""
    echo "✅ 시뮬레이터 부팅 완료!"
else
    echo "✅ 시뮬레이터가 이미 실행 중입니다."
fi

# 추가 안정화 대기
sleep 3

# Flutter 디바이스 확인
echo "🔍 Flutter 디바이스 확인 중..."
flutter devices

# Flutter 앱 실행
echo "🎯 Flutter 앱 실행 중..."
flutter run -d "$DEVICE_ID" || flutter run -d ios

