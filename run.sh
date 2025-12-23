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
        bash run_android.sh &
        sleep 5
        bash run_ios.sh
        ;;
    *)
        echo "❌ 잘못된 선택입니다."
        exit 1
        ;;
esac

