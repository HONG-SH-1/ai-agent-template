# Project CLAUDE.md

## 1. 세션 부트스트랩 (MANDATORY)
```bash
cat error_log.md
cat docs/checklist.md 2>/dev/null || echo "[INFO] 없음"
```
코드 한 줄도 건드리지 마라.
docs/plan.md에 목적/수정파일/순서 작성 후 승인 대기.

## 2. 정적 분석 (작업 완료 전)
```bash
grep -rn "new String(" src/main/java/ && echo "[WARNING]" || echo "[OK]"
grep -rniE "(secret|password|token)\s*=\s*['\"][^$\{]" src/main/java/ && echo "[WARNING]" || echo "[OK]"
find src/main/java -path "*/vo/*.java" | xargs grep -L "hashCode" 2>/dev/null && echo "[WARNING]" || echo "[OK]"
```
주의: @Transactional grep은 구조상 오탐 100%. 트랜잭션 검증은 테스트 코드로 담보.

## 3. Definition of Done
```bash
mvn clean test   # OS 무관 동일 명령어
```
BUILD SUCCESS만 완료. 결과 로그 출력 필수.

