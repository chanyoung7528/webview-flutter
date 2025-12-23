#!/bin/bash

# 통합 실행 스크립트 (플랫폼 선택)

echo "🎯 삼성아파트 웹뷰 앱 실행"
echo ""
echo "실행할 플랫폼을 선택하세요:"
echo "1) Android 에뮬레이터"
echo "2) iOS 시뮬레이터"
echo "3) 둘 다 실행 (Android 먼저)"
echo ""
read -p "선택 (1-3): " choice

case $choice in
    1)
        echo "📱 Android 에뮬레이터 실행 중..."
        bash run_android.sh
        ;;
    2)
        echo "🍎 iOS 시뮬레이터 실행 중..."
        bash run_ios.sh
        ;;
    3)
        echo "📱🍎 Android와 iOS 모두 실행 중..."
        
        # Android 에뮬레이터 실행
        echo "🚀 Android 에뮬레이터 실행 중..."
        EMULATOR_NAME=$(emulator -list-avds | head -n 1)
        if [ -z "$EMULATOR_NAME" ]; then
            echo "❌ 사용 가능한 에뮬레이터가 없습니다."
            exit 1
        fi
        echo "✅ 에뮬레이터 실행: $EMULATOR_NAME"
        emulator -avd "$EMULATOR_NAME" > /dev/null 2>&1 &
        adb wait-for-device
        echo "⏳ Android 에뮬레이터 완전 부팅 대기 중..."
        MAX_WAIT=120
        WAIT_COUNT=0
        while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
            BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
            if [ "$BOOT_COMPLETED" = "1" ]; then
                echo "✅ Android 에뮬레이터 부팅 완료!"
                break
            fi
            sleep 2
            WAIT_COUNT=$((WAIT_COUNT + 2))
            echo -n "."
        done
        echo ""
        sleep 5
        adb kill-server 2>/dev/null
        sleep 2
        adb start-server 2>/dev/null
        sleep 2
        
        # iOS 시뮬레이터 실행
        echo "🚀 iOS 시뮬레이터 실행 중..."
        DEVICE_INFO=$(xcrun simctl list devices available | grep -i "iPhone" | grep -v "unavailable" | head -n 1)
        if [ -z "$DEVICE_INFO" ]; then
            echo "❌ 사용 가능한 iPhone 시뮬레이터가 없습니다."
            exit 1
        fi
        DEVICE_ID=$(echo "$DEVICE_INFO" | grep -oE '[A-F0-9-]{36}' | head -n 1)
        BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted" || echo "")
        if [ -z "$BOOT_STATUS" ]; then
            echo "🔄 iOS 시뮬레이터 부팅 중..."
            xcrun simctl boot "$DEVICE_ID" 2>/dev/null
            open -a Simulator
            while [ -z "$(xcrun simctl list devices | grep "$DEVICE_ID" | grep "Booted")" ]; do
                sleep 2
            done
            echo "✅ iOS 시뮬레이터 부팅 완료!"
        fi
        sleep 3
        
        # Flutter 디바이스 확인
        echo "🔍 Flutter 디바이스 확인 중..."
        flutter devices
        
        # Android 디바이스 ID 가져오기 (emulator-로 시작하는 ID 추출)
        # "unsupported" 상태도 포함해서 찾기
        ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -oE "emulator-[0-9]+" | head -n 1)
        if [ -z "$ANDROID_DEVICE" ]; then
            ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -E "(android-arm64|unsupported)" | grep -oE "emulator-[0-9]+" | head -n 1)
        fi
        if [ -z "$ANDROID_DEVICE" ]; then
            ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -oE "emulator-[0-9]+" | head -n 1)
        fi
        
        # iOS 디바이스 ID 가져오기 (UUID 형식 추출)
        IOS_DEVICE=$(flutter devices 2>/dev/null | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" | head -n 1)
        
        if [ -z "$ANDROID_DEVICE" ] || [ -z "$IOS_DEVICE" ]; then
            echo "❌ 디바이스를 찾을 수 없습니다."
            flutter devices
            exit 1
        fi
        
        echo "✅ Android 디바이스: $ANDROID_DEVICE"
        echo "✅ iOS 디바이스: $IOS_DEVICE"
        
        # 두 디바이스에 동시에 앱 실행
        echo "🎯 Android에 Flutter 앱 실행 중..."
        flutter run -d "$ANDROID_DEVICE" &
        ANDROID_PID=$!
        
        sleep 3
        
        echo "🎯 iOS에 Flutter 앱 실행 중..."
        flutter run -d "$IOS_DEVICE" &
        IOS_PID=$!
        
        # 두 프로세스가 종료될 때까지 대기
        wait $ANDROID_PID
        wait $IOS_PID
        ;;
    *)
        echo "❌ 잘못된 선택입니다."
        exit 1
        ;;
esac

