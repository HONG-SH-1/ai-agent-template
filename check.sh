#!/bin/bash
# ============================================================
# check.sh — 정적 분석 + 테스트 자동화 스크립트
# Claude Code 대신 사용. 빠르고 토큰 낭비 없음.
# 사용법: ./check.sh [working_directory]
# 예시:   ./check.sh Backend-main
# ============================================================

set -e

WORK_DIR=${1:-.}
SRC_DIR="$WORK_DIR/src/main/java"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
RESULT_LOG="check_result.log"

echo "========================================"
echo "  AI-Agent Check Script"
echo "  실행 시간: $TIMESTAMP"
echo "  대상 경로: $WORK_DIR"
echo "========================================"

# ── 1. 디렉토리 존재 확인 ──────────────────
if [ ! -d "$WORK_DIR" ]; then
  echo "[ERROR] 경로가 존재하지 않습니다: $WORK_DIR"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "[WARN] Java 소스 디렉토리 없음: $SRC_DIR (스킵)"
  SRC_DIR=""
fi

WARNINGS=0
ERRORS=0

# ── 2. 정적 분석 ──────────────────────────
echo ""
echo "[ 정적 분석 시작 ]"

if [ -n "$SRC_DIR" ]; then

  # 2-1. new String() 탐지
  echo -n "  new String() 탐지... "
  RESULT=$(grep -rn "new String(" "$SRC_DIR" 2>/dev/null || true)
  if [ -n "$RESULT" ]; then
    echo "[WARNING]"
    echo "$RESULT"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "[OK]"
  fi

  # 2-2. 민감정보 하드코딩 탐지
  echo -n "  민감정보 하드코딩 탐지... "
  RESULT=$(grep -rniE "(secret|password|token)\s*=\s*['\"][^$\{]" "$SRC_DIR" 2>/dev/null || true)
  if [ -n "$RESULT" ]; then
    echo "[WARNING]"
    echo "$RESULT"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "[OK]"
  fi

  # 2-3. VO/DTO hashCode 누락 탐지
  echo -n "  hashCode 누락 탐지... "
  RESULT=$(find "$SRC_DIR" -path "*/vo/*.java" -o -path "*/dto/*.java" 2>/dev/null \
    | xargs grep -L "hashCode" 2>/dev/null || true)
  if [ -n "$RESULT" ]; then
    echo "[WARNING]"
    echo "$RESULT"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "[OK]"
  fi

  # 2-4. System.out.println 탐지 (운영 로그 오염)
  echo -n "  System.out.println 탐지... "
  RESULT=$(grep -rn "System\.out\.println" "$SRC_DIR" 2>/dev/null || true)
  if [ -n "$RESULT" ]; then
    echo "[WARNING]"
    echo "$RESULT"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "[OK]"
  fi

  # 2-5. TODO/FIXME 탐지
  echo -n "  TODO/FIXME 탐지... "
  RESULT=$(grep -rn "TODO\|FIXME" "$SRC_DIR" 2>/dev/null || true)
  if [ -n "$RESULT" ]; then
    echo "[INFO] (참고용)"
    echo "$RESULT"
  else
    echo "[OK]"
  fi

fi

# ── 3. 빌드 및 테스트 ─────────────────────
echo ""
echo "[ 빌드 및 테스트 시작 ]"

cd "$WORK_DIR"

# Maven 감지
if [ -f "pom.xml" ]; then
  echo "  빌드 도구: Maven"
  mvn clean test -q
  EXIT_CODE=$?

# Gradle 감지
elif [ -f "gradlew" ]; then
  echo "  빌드 도구: Gradle"
  ./gradlew clean test --no-daemon -q
  EXIT_CODE=$?

elif [ -f "gradlew.bat" ]; then
  echo "  빌드 도구: Gradle (Windows)"
  ./gradlew.bat clean test --no-daemon -q
  EXIT_CODE=$?

# Node.js 감지
elif [ -f "package.json" ]; then
  echo "  빌드 도구: npm"
  npm test
  EXIT_CODE=$?

# Python 감지
elif [ -f "requirements.txt" ]; then
  echo "  빌드 도구: pytest"
  pytest -v
  EXIT_CODE=$?

else
  echo "  [WARN] 빌드 도구를 감지할 수 없습니다."
  EXIT_CODE=0
fi

cd - > /dev/null

# ── 4. 결과 요약 ──────────────────────────
echo ""
echo "========================================"
echo "  결과 요약"
echo "========================================"
echo "  정적 분석 경고: $WARNINGS 개"

if [ $EXIT_CODE -eq 0 ]; then
  echo "  빌드/테스트: BUILD SUCCESS ✅"
  BUILD_STATUS="SUCCESS"
else
  echo "  빌드/테스트: BUILD FAILURE ❌"
  BUILD_STATUS="FAILURE"
  ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -gt 0 ]; then
  echo "  [FAIL] 에러 발생. 수정 후 재실행하세요."
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo "  [WARN] 경고 있음. 확인 후 진행하세요."
  exit 0
else
  echo "  [PASS] 모든 검사 통과. ✅"
  exit 0
fi
