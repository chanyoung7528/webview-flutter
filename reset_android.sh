#!/bin/bash

# Android 에뮬레이터 초기화 및 캐시 삭제 스크립트

echo "🧹 Android 에뮬레이터 초기화 및 캐시 삭제 중..."

# 실행 중인 에뮬레이터 종료
echo "🛑 실행 중인 에뮬레이터 종료 중..."
RUNNING_EMULATORS=$(adb devices | grep "emulator" | awk '{print $1}')
if [ -n "$RUNNING_EMULATORS" ]; then
    for emulator in $RUNNING_EMULATORS; do
        echo "  - $emulator 종료 중..."
        adb -s "$emulator" emu kill 2>/dev/null || true
    done
    sleep 3
fi

# ADB 서버 재시작
echo "🔄 ADB 서버 재시작 중..."
adb kill-server 2>/dev/null
sleep 2
adb start-server 2>/dev/null
sleep 2

# Flutter 빌드 캐시 삭제
echo "🗑️  Flutter 빌드 캐시 삭제 중..."
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# Android 빌드 캐시 삭제
echo "🗑️  Android 빌드 캐시 삭제 중..."
cd android
./gradlew clean 2>/dev/null || true
rm -rf .gradle/
rm -rf app/build/
rm -rf build/
cd ..

# 에뮬레이터 목록 표시
echo ""
echo "📱 사용 가능한 에뮬레이터 목록:"
emulator -list-avds

# 에뮬레이터 초기화 옵션
echo ""
echo "에뮬레이터를 초기화하시겠습니까? (데이터가 모두 삭제됩니다)"
read -p "초기화할 에뮬레이터 이름을 입력하세요 (또는 Enter로 건너뛰기): " EMULATOR_NAME

if [ -n "$EMULATOR_NAME" ]; then
    echo "⚠️  에뮬레이터 '$EMULATOR_NAME' 초기화 중..."
    echo "⚠️  경고: 모든 데이터가 삭제됩니다!"
    read -p "정말로 초기화하시겠습니까? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        # 에뮬레이터 삭제 및 재생성
        echo "🗑️  에뮬레이터 삭제 중..."
        avdmanager delete avd -n "$EMULATOR_NAME" 2>/dev/null || true
        
        echo "✅ 에뮬레이터가 삭제되었습니다."
        echo "💡 Android Studio에서 에뮬레이터를 다시 생성해주세요."
    else
        echo "❌ 초기화가 취소되었습니다."
    fi
else
    echo "✅ 에뮬레이터 초기화를 건너뜁니다."
fi

# Gradle 캐시 삭제 (선택사항)
echo ""
read -p "Gradle 캐시도 삭제하시겠습니까? (y/n): " DELETE_GRADLE

if [ "$DELETE_GRADLE" = "y" ]; then
    echo "🗑️  Gradle 캐시 삭제 중..."
    rm -rf ~/.gradle/caches/
    rm -rf ~/.gradle/daemon/
    echo "✅ Gradle 캐시가 삭제되었습니다."
fi

echo ""
echo "✅ 초기화 완료!"
echo ""
echo "다음 단계:"
echo "1. ./run_android.sh 를 실행하여 에뮬레이터를 시작하세요"
echo "2. 또는 Android Studio에서 에뮬레이터를 실행하세요"

