# Project CLAUDE.md

## 1. 세션 부트스트랩 (MANDATORY)
```bash
cat error_log.md 2>/dev/null || echo "[INFO] New Project"
cat docs/checklist.md 2>/dev/null || echo "[INFO] No checklist"
```
코드 한 줄도 건드리지 마라.
docs/plan.md 작성 후 승인 대기.

## 2. 규칙 참조 (Lazy Loading)
- 고위험 파일 목록 → docs/high_risk_areas.md
- 운영 규칙 → docs/ops_guide.md
- Java 보안 패턴 → .claude/skills/java-security-guide.md
- 전체 설계 원칙 → docs/FINAL_COMPLETE_GUIDE.md

## 3. 정적 분석 (작업 완료 전)
```bash
# 방법 1: 자동화 스크립트 (권장)
./check.sh [working_directory]

# 방법 2: 수동 실행
grep -rn "new String(" [src_dir] && echo "[WARNING]" || echo "[OK]"
grep -rniE "(secret|password|token)\s*=\s*['\"][^$\{]" [src_dir] && echo "[WARNING]" || echo "[OK]"
find [src_dir] -path "*/vo/*.java" | xargs grep -L "hashCode" 2>/dev/null && echo "[WARNING]" || echo "[OK]"
```
주의: @Transactional grep은 오탐 100%. 테스트 코드로 검증.

## 4. Definition of Done
```bash
# .ci/project.yml의 test_command 실행
./check.sh [working_directory]
```
BUILD SUCCESS + 로그 출력 + checklist.md 갱신 후에만 완료.

## 5. 고위험 파일 처리
→ 상세 목록: docs/high_risk_areas.md 참조
→ 규칙: .cursor/rules/high-risk-files.mdc 참조
Claude Code 자율 루프 시 고위험 파일 수정 절대 금지.

## 6. Claude Code 자율 루프 허용 범위
허용:
- 일반 비즈니스 로직 구현
- 테스트 코드 작성
- SQL 쿼리 작성
- 빌드 에러 수정 (고위험 파일 제외)

금지:
- Auth/Security/Payment/Transaction 파일 수정
- DB 스키마 직접 변경
- 환경변수/설정 파일 수정
- git push 자율 실행
