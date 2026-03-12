## 버전 히스토리

| 버전 | 날짜 | 변경 내용 | 변경 이유 |
|------|------|-----------|-----------|
| v1.0 | 2026-03-12 | 최초 작성 | Claude+Cursor+Gemini 교차검증 완료 |

변경 원칙: `.cursorrules`, `CLAUDE.md`, `ci.yml`이 바뀌면 이 테이블에 반드시 한 줄 추가한다.

# AI 에이전트 환경 완전 설계 가이드
## Claude + Cursor + Claude Code + GitHub CI 통합 시스템
### 작성 배경: Claude, Cursor, Gemini 3개 AI 교차 검증 및 반복 개선으로 수렴한 최종 설계

---

## 목차

1. 전체 시스템 철학 및 원칙
2. 도구 역할 확정 (4개 AI 분업)
3. 파일 구조 전체
4. Cursor 환경 설정 (`.cursorignore` / `.cursorrules`)
5. Claude Code 환경 설정 (`CLAUDE.md` 2계층)
6. GitHub CI 설정 (`ci.yml` + `project.yml`)
7. 문서 파일 시스템 (`plan.md` / `checklist.md` / `error_log.md`)
8. 실전 워크플로우 (기능 1개 완성까지의 흐름)
9. 팩트 검증 기록 (세 AI 교차검증 결과)
10. Branch Protection 설정 가이드
11. 완성 체크리스트

---

## 1. 전체 시스템 철학 및 원칙

### 핵심 철학

이 시스템은 세 가지 원칙 위에 설계되어 있다.

**원칙 1: 수치가 아닌 구조로 판단한다**
"5.5배 토큰 효율" 같은 검증되지 않은 벤치마크 수치는 조건 의존이 크고 출처가 불분명하다. 각 도구가 어떻게 동작하는지 원리로 판단하고 구조를 설계한다.

**원칙 2: 강제력 없는 규칙은 약하다. 게이트로 보완한다**
AI에게 "해줘"라고 부탁하는 것(지시 기반)이 아니라, 하지 않으면 진행이 안 되는 구조(강제 실행 기반)를 만든다. Cursor는 구조적 훅이 없으므로 "승인 키워드 게이트 + diff 개별 확인"을 사람이 지켜야 한다.

**원칙 3: 두 계층의 방어선**
- 기존 방어선: AI가 규칙을 위반하는 것을 막는다
- 추가 방어선: AI가 규칙을 따르면서도 실패하는 것을 막는다 (확증편향, 스코프 크립, 에러루프, 확신 과잉, 커버리지 착시)

### 이 시스템이 방지하는 실패 목록

| 실패 유형 | 방지 수단 |
|-----------|-----------|
| Claude가 검증 없이 "했다"고 환각 | bash 명령 실행 + 결과 출력 강제 |
| 잘못된 방향으로 대량 파일 수정 | plan.md 승인 게이트 |
| 동일한 실수 반복 | error_log.md 세션 시작 시 읽기 |
| 민감 정보 하드코딩 | 정적 분석 + 코딩 규칙 |
| Accept All로 전체 파일 예상치 못하게 변경 | 고위험 파일 Accept All 절대 금지 |
| DB가 AI 실수로 변경 | Read-Only DB 계정 (강력 권장) |
| CI 실패해도 머지 | Branch Protection 필수 체크 |
| 계획 충돌 신호 무시 | 계획 충돌 감지 보고 규칙 |
| 조용한 범위 확장 | 범위 초과 감지 보고 규칙 |
| 에러 패치 무한 반복 | 에러 루프 2회 멈춤 규칙 |
| 확신 없는 내용을 확신처럼 제안 | 확신도 태그 의무화 |
| 테스트 통과 = 올바른 코드 착시 | 고위험 셀프 체크 의무 |

---

## 2. 도구 역할 확정

### 4개 AI 도구 완전 분업

```
Claude.ai (설계실)
  역할: 설계, 문서, 의사결정, 아이디어 검토
  언제: 구조 설계, 복잡한 논리 다듬기, 이 가이드처럼 전략 문서 작성
  왜: 대화 기반으로 복잡한 논리를 다듬는 데 최적화

Cursor Pro (수술실)
  역할: 파일 단위 정밀 수정, IDE 작업, diff 확인
  언제: 특정 메서드 수정, 새 기능 구현, 코드 분석
  왜: Accept/Reject로 사람이 마지막 게이트를 지킬 수 있음
  핵심: 강제 훅이 없으므로 .cursorrules + 사람의 게이트 운영이 핵심

Claude Code (자동화 공장)
  역할: 전체 테스트 루프, 정적 분석, 에러 로그 자동화
  언제: 기능 완료 후 검증, 코드베이스 전체 패턴 탐색, 일괄 리팩토링
  왜: bash 명령어 강제 실행으로 검증을 구조적으로 강제 가능

Gemini Pro (자료실)
  역할: 대용량 파일 분석, 이미지 분석, 레퍼런스 검토
  언제: 100페이지 이상 문서, 대용량 PDF, 멀티모달 작업
  왜: 컨텍스트 창이 커서 대용량 처리에 유리한 편
  주의: 벤치마크 수치를 과장하거나 검증 안 된 명령어를 제시하는 경향 있음
```

### 같은 작업에서 도구 전환 기준

| 상황 | 사용 도구 |
|------|-----------|
| 새 기능 설계, 여러 파일 생성 | Cursor Composer (Ctrl+I) |
| 특정 메서드/블록 정밀 수정 | Cursor Inline Edit (Ctrl+K) |
| 코드 분석, 구조 이해 (수정 없음) | Cursor Chat (Ctrl+L) |
| 전체 테스트 루프, 에러 로그 기록 | Claude Code |
| 코드베이스 전체 패턴 탐색 | Claude Code |
| 구조 설계, 전략 논의 | Claude.ai |

---

## 3. 파일 구조 전체

### 프로젝트 루트 기준 완전 파일 트리

```
project-root/
 ├── .cursorrules                    ← Cursor AI 규칙 (이 파일의 내용 참고)
 ├── .cursorignore                   ← Cursor 인덱싱 제외 파일
 ├── CLAUDE.md                       ← Claude Code 프로젝트 규칙 (반드시 대문자)
 ├── error_log.md                    ← 에러 히스토리 (세션 간 기억 외부화)
 │
 ├── .ci/
 │    └── project.yml               ← CI 설정 (이 파일만 프로젝트마다 수정)
 │
 ├── .github/
 │    └── workflows/
 │         └── ci.yml               ← 범용 CI 게이트 (절대 수정하지 않음)
 │
 ├── .claude/
 │    └── skills/                   ← 도메인별 스킬 파일
 │         ├── java-security-guide.md
 │         └── python-websocket-guide.md
 │
 └── docs/
      ├── plan.md                   ← 작업 계획서 (승인 게이트)
      └── checklist.md              ← 프로젝트 진행 상태
```

### 전역 Claude Code 설정 (모든 프로젝트 공통)

```
~/.claude/
 └── CLAUDE.md                      ← 전역 규칙 (모든 프로젝트에 자동 적용)
```

프로젝트의 `CLAUDE.md`와 전역 `~/.claude/CLAUDE.md`는 합쳐져서 읽힌다. 전역에는 모든 프로젝트 공통 원칙, 프로젝트 파일에는 이 프로젝트 전용 규칙을 담는다.

---

## 4. Cursor 환경 설정

### 4-1. 계정 및 보안 설정

- **전용 계정 생성 권장**: 프로젝트 코드가 어떤 계정을 통해 AI에게 전달되는지 추적 가능해야 함. 의료 데이터 보호 플랫폼은 감사(Audit) 관점에서 필요
- **Privacy Mode 활성화**: Settings에서 켜기. 코드가 모델 학습에 사용되지 않도록. "학습 사용 최소화 목적"으로 이해하는 것이 정확 (정책/구현 변경 가능성 있음)
- **Spend Limit 설정 필수**: Settings → Billing에서 월별 한도 설정. Auto 모드를 벗어나 프리미엄 모델 수동 선택 시 크레딧 빠르게 소진
- **평소 Auto 모드 유지**: Auto가 작업 복잡도에 따라 모델을 자동 선택함. 모델 고정은 크레딧 낭비. 수동 선택은 복잡한 작업 단위로만, 끝나면 Auto 복귀

### 4-2. .cursorignore (복붙용)

이 파일 없으면 빌드 결과물, 로그, 민감 설정 파일이 AI 컨텍스트로 올라간다. 두 가지 문제: 컨텍스트 낭비 + 민감 정보 노출.

```
# 빌드 결과물
**/build/**
**/target/**
**/.gradle/**
**/dist/**
**/out/**

# IDE 설정
**/.idea/**
**/.vscode/**
**/*.iml

# 로그 및 임시 파일
**/*.log
**/*.tmp
**/logs/**

# 의존성
**/node_modules/**
**/.m2/**

# 민감 설정 (절대 AI에게 보이면 안 됨)
**/*.env
**/application-prod.yml
**/application-local.yml
**/db_dump/**
**/*.key
**/*.pem
```

### 4-3. .cursorrules 완전 최종본 (복붙용)

Claude, Cursor, Gemini 3개 AI가 반복 검증하고 수렴한 최종본.

```markdown
# Universal Cursor Rules — Absolute Final
# Claude + Cursor + Gemini 3개 AI 교차검증 완료

## [세션 시작 — MANDATORY]
작업 시작 전 docs/plan.md + docs/checklist.md + error_log.md 를 읽고 각각 1줄 요약해라.
파일이 없으면 "[없음]" 으로 표기. 요약 없이 진행 금지.

## [계획 게이트]
docs/plan.md 에 (목표 / 변경 파일 / 리스크 / 대책) 작성 후 "승인" 요청.
"승인 / 진행해 / OK / 계획 승인" 전에는 코드 편집(적용/수정) 금지.
설명 / 대안 / 리스크 토론은 승인 전에도 가능.

## [데이터 무결성 — 파괴적 작업 금지]
승인 없이 금지:
- git push --force / -f
- DB DROP / 대량 DELETE / 마이그레이션 강행
- rm -rf 등 재귀 삭제
커밋 / 푸시 / 배포는 반드시 사전 보고 후 승인.

## [롤백 계획 의무]
DB 마이그레이션 / 스키마 변경 / 데이터 변환 작업 전 반드시 보고:
"[롤백 계획] 방법: X / 예상 소요: Y"
롤백 계획 없는 비가역 작업 시작 금지.

## [고위험 파일 게이트]
Auth / Security / Transaction / Payment 관련 변경:
- Accept All 절대 금지 — 파일별 diff 개별 승인만
- 파일 전체 덮어쓰기 금지 — 메서드/블록 단위 수정만
- 완료 후 셀프 체크:
  → null / 빈 값 / 권한 없는 사용자 시나리오 테스트 있는가?
  → 없으면 "[테스트 커버리지 부족]" 보고 + 테스트 1개 추가 제안

## [코딩 규칙]
- 민감정보(secret / password / token) 하드코딩 금지 → 환경변수로
- Java: VO/DTO는 equals() + hashCode() 필수
- Java: @Transactional은 grep 금지, 코드 리뷰 + 테스트로 담보
- Python: WebSocket은 disconnect / timeout 예외 처리 필수

## [의존성 추가 체크]
새 라이브러리 추가 시 반드시 포함:
"[의존성 체크] 라이선스: X / CVE 여부: Y(확인 필요 허용, 단정 금지) / 마지막 업데이트: Z"
GPL 계열은 별도 검토 요청.

## [완료 기준 — DoD]
.ci/project.yml 의 test_command 를 working_directory 에서 실행.
Windows:   .\gradlew.bat clean test
Mac·Linux: ./gradlew clean test
Maven:     mvn clean test
BUILD SUCCESS + 명령어/종료결과/핵심 로그 + docs/checklist.md 갱신 후에만 완료 보고.

## [코드 생략 금지]
"// 기존 로직 유지" / "// 동일 패턴으로" / "나머지는 같은 방식으로" 금지.
생략 불가피 시: "[생략 경고] 직접 구현 필요: 이유" 명시.

## [추가 방어선 — AI 내부 실패 패턴 대응]

[계획 충돌 감지]
구현 중 plan과 충돌 신호 발견 시 즉시 멈추고:
"[계획 충돌] 발견 내용 / 원래 계획 / 권장 조치"
승인 없이 계획 임의 수정 / 무시 금지.

[범위 초과 감지]
plan에 없는 파일 수정 / 새 파일 생성 / 리네임 / 의존성 추가 시 즉시:
"[범위 초과] 대상: X / 이유: Y"
승인 없이 범위 밖 변경 금지.

[에러 루프 감지]
같은 테스트 / 같은 스택트레이스 핵심으로 수정 2회 반복 시 즉시:
"[에러 루프] 에러 / 시도1 / 시도2 / 현재 판단"
3번째 시도 전 방향 승인 요청.

[확신도 태그]
결정 / 명령 / 위험 변경 제안에 명시:
[확신] 검증됨 / [추정] 일반론 기반 확인 필요 / [불확실] 사람 판단 필요
[추정] / [불확실] 제안은 사람이 직접 검증 후 적용.

[세션 관리]
대화가 길어지거나 중요 규칙 재확인이 필요하면:
"[세션 정리 권장] /clear 전에 checklist.md + error_log.md 업데이트 권장"
```

### 4-4. 단축키 용도 분리 원칙

이 세 가지를 섞어 쓰면 컨텍스트가 오염된다.

- **Ctrl+I (Composer)**: 여러 파일 동시 수정, 새 기능 구현. plan.md 승인 후 사용. Accept All은 고위험 파일에서 절대 금지
- **Ctrl+K (Inline Edit)**: 특정 메서드/블록 정밀 수정. Auth, 결제, 트랜잭션 로직은 전부 이 방식으로 처리
- **Ctrl+L (Chat)**: 코드 수정 없이 분석, 이해, 질문. 이 창에서는 수정 지시 내리지 않는 것을 원칙으로

---

## 5. Claude Code 환경 설정

### 5-1. 전역 CLAUDE.md (~/.claude/CLAUDE.md)

모든 프로젝트에 자동 적용. "어떤 프로젝트에서든 Claude가 항상 지켜야 할 것"만 담는다.

```markdown
# Global Rules — 모든 프로젝트 공통

## 세션 부트스트랩 (MANDATORY)
```bash
cat error_log.md 2>/dev/null || echo "[INFO] 신규 프로젝트"
cat docs/checklist.md 2>/dev/null || echo "[INFO] 체크리스트 없음"
```
코드 한 줄도 건드리지 마라.
docs/plan.md 작성 후 승인 대기.

## 에러 로그 기록
```bash
cat >> error_log.md << EOF
## [$(date +'%Y-%m-%d')]
- 도메인: 
- 문제: 
- 원인: 
- 해결: 
- 재발 방지: 
EOF
```

## 전역 금지
- 승인 없이 코드 수정 금지
- 테스트 없이 완료 선언 금지
- 민감정보 하드코딩 금지
- 원인 파악 없이 임의 수정 금지
```

### 5-2. 프로젝트 CLAUDE.md 핵심 원칙

**CLAUDE.md는 짧을수록 좋다.** 이유: 대화가 길어지면 Claude는 컨텍스트를 압축하는데, 파일이 길면 규칙이 희석된다. 핵심만 남기고 세부 내용은 스킬 파일로 분리한다.

**세션 부트스트랩은 반드시 bash 명령어로 작성해야 한다.** "error_log.md를 읽어라"라고 문장으로 쓰면 Claude가 읽었다고 주장만 해도 확인이 안 된다. `cat error_log.md`를 실행하고 결과를 출력하게 하면, 출력이 보이지 않으면 실행하지 않은 것이 드러난다.

```markdown
# Project CLAUDE.md (프로젝트별 수정)

## 1. 세션 부트스트랩 (MANDATORY)
```bash
cat error_log.md
cat docs/checklist.md 2>/dev/null || echo "[INFO] 없음"
```
코드 한 줄도 건드리지 마라.
docs/plan.md에 목적/수정파일/순서 작성 후 승인 대기.

## 2. 도메인별 스킬 로드 (해당 작업 시에만)
```bash
# Auth 도메인: cat .claude/skills/java-security-guide.md
# WebSocket:   cat .claude/skills/python-websocket-guide.md
```

## 3. 정적 분석 (작업 완료 전)
```bash
grep -rn "new String(" src/main/java/ && echo "[WARNING]" || echo "[OK]"
grep -rniE "(secret|password|token)\s*=\s*['\"][^$\{]" src/main/java/ && echo "[WARNING]" || echo "[OK]"
find src/main/java -path "*/vo/*.java" | xargs grep -L "hashCode" 2>/dev/null && echo "[WARNING]" || echo "[OK]"
```
주의: @Transactional grep은 구조상 오탐 100%. 트랜잭션 검증은 테스트 코드로 담보.

## 4. Definition of Done
```bash
./gradlew clean test   # Windows: .\gradlew.bat clean test
```
BUILD SUCCESS만 완료. 결과 로그 출력 필수.

## 5. 에러 로그
에러 발생 시 error_log.md에 기록 후 checklist.md 업데이트.
```

### 5-3. 스킬 시스템 원리

스킬 파일은 세션 시작 시 모두 읽히지 않는다. **해당 도메인 작업을 할 때만 `cat` 명령어로 읽는다.** 필요한 시점에 필요한 스킬만 올리는 것이 컨텍스트를 작업에 집중시키는 핵심이다.

시간이 쌓일수록 스킬 파일은 강해진다. error_log.md에 같은 도메인의 실수가 두 번 이상 반복되면 해당 내용을 스킬 파일에 추가한다. 처음에는 일반적인 베스트 프랙티스였던 파일이 프로젝트 전용 경험 데이터베이스로 진화한다.

### 5-4. 세션 관리 원칙

`/clear` 전에 반드시:
1. error_log.md에 이번 세션 에러 기록
2. docs/checklist.md에 완료 작업 업데이트

이 두 파일이 업데이트된 후 세션을 초기화하면, 새 세션에서 이 파일들을 읽어 맥락이 복원된다. **기억은 파일에 남아있고 컨텍스트 창만 깨끗해지는 구조다.**

---

## 6. GitHub CI 설정

### 6-1. 설계 원칙

**"CI 파일 고정 + 프로젝트마다 매니페스트 1개만 수정"**

- `ci.yml`: 모든 프로젝트 공통. 절대 수정하지 않음
- `.ci/project.yml`: 프로젝트마다 이것만 수정
- 새 프로젝트 투입 = `.ci/project.yml` 만 새로 작성

**이 구조가 범용인 이유**: CI가 "어디서/무엇을/어떤 버전으로" 실행할지를 알아야 하는데, 이것이 프로젝트마다 다르다. 달라지는 부분만 매니페스트로 분리하고 공통 로직은 워크플로우에 고정한다.

**왜 CI가 필요한가**: Cursor에는 구조적 훅이 없어서 로컬에서 실수로 Accept All을 하거나 테스트를 빼먹어도 막을 방법이 없다. GitHub CI가 테스트 실패를 잡고 merge를 구조적으로 차단하는 것이 유일한 서버 측 강제력이다.

### 6-2. .ci/project.yml (복붙용)

**이 파일만 프로젝트마다 수정한다.**

```yaml
# ============================================================
# 프로젝트 CI 설정 — .ci/project.yml
# 이 파일만 프로젝트에 맞게 수정. ci.yml은 수정하지 않음.
# ============================================================

jobs:

  # ── Java 백엔드 (Gradle) ──────────────────────────────────
  - name: backend-java
    runs_on: ubuntu-latest        # ubuntu-latest / windows-latest
    working_directory: .          # 서브디렉토리면 Backend-main 등
    runtime:
      language: java              # java / python / node
      version: "17"               # Java: 17, 21, 11
    build_tool: gradle            # gradle / maven / pip / poetry / npm / pnpm / yarn
    test_command: ./gradlew clean test --no-daemon
    # install_command 없으면 이 줄 삭제 (빈 값 넣지 말 것)

  # ── Python 서비스 추가 시 아래 주석 해제 ─────────────────
  # - name: realtime-python
  #   runs_on: ubuntu-latest
  #   working_directory: realtime
  #   runtime:
  #     language: python
  #     version: "3.11"
  #   build_tool: pip
  #   install_command: pip install -r requirements.txt
  #   test_command: pytest tests/ -v

  # ── Node 프론트엔드 추가 시 아래 주석 해제 ───────────────
  # - name: frontend-node
  #   runs_on: ubuntu-latest
  #   working_directory: frontend
  #   runtime:
  #     language: node
  #     version: "20"
  #   build_tool: npm
  #   install_command: npm ci
  #   test_command: npm test
```

### 6-3. .github/workflows/ci.yml (복붙용)

**이 파일은 절대 수정하지 않는다. 모든 프로젝트에서 그대로 사용.**

```yaml
# ============================================================
# Universal CI Gateway v5 (Final)
#
# [필수 설정 — 이 파일만으론 머지 차단 안 됨]
# GitHub → Settings → Branches → Branch protection rules
#   → main/master 에 룰 생성
#   → "Require status checks to pass" 체크
#   → 필수 체크: "test / {job name}" (예: "test / backend-java")
#   → "Require pull request reviews" 권장
#
# [사용법]
# 1. 이 파일은 절대 수정하지 않음
# 2. .ci/project.yml 만 프로젝트에 맞게 수정
# 3. 새 프로젝트 = .ci/project.yml 만 새로 작성
# ============================================================

name: CI Gate

on:
  pull_request:
  push:
    branches: [ "main", "master", "develop" ]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:

  load-manifest:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.parse.outputs.matrix }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Validate manifest exists
        shell: bash
        run: |
          if [ ! -f ".ci/project.yml" ]; then
            echo "::error::.ci/project.yml 파일이 없습니다."
            echo "::error::형식 예시:"
            echo "::error::  jobs:"
            echo "::error::    - name: backend-java"
            echo "::error::      runs_on: ubuntu-latest"
            echo "::error::      working_directory: ."
            echo "::error::      runtime: { language: java, version: \"17\" }"
            echo "::error::      build_tool: gradle"
            echo "::error::      test_command: ./gradlew clean test --no-daemon"
            exit 1
          fi

      - name: Validate manifest keys
        uses: mikefarah/yq@v4
        with:
          cmd: |
            set -euo pipefail
            errors=0
            check_field() {
              local val
              val="$(yq "$1" .ci/project.yml 2>/dev/null || true)"
              if [ -z "$val" ] || [ "$val" = "null" ]; then
                echo "::error::필수 키 누락 또는 빈 값: $2"
                errors=$((errors + 1))
              fi
            }
            count="$(yq '.jobs | length' .ci/project.yml)"
            for i in $(seq 0 $((count - 1))); do
              check_field ".jobs[$i].name"              "jobs[$i].name"
              check_field ".jobs[$i].runs_on"           "jobs[$i].runs_on"
              check_field ".jobs[$i].working_directory" "jobs[$i].working_directory"
              check_field ".jobs[$i].runtime.language"  "jobs[$i].runtime.language"
              check_field ".jobs[$i].runtime.version"   "jobs[$i].runtime.version"
              check_field ".jobs[$i].build_tool"        "jobs[$i].build_tool"
              check_field ".jobs[$i].test_command"      "jobs[$i].test_command"
            done
            if [ "$errors" -gt 0 ]; then
              echo "::error::필수 키 누락 ${errors}건. 위 에러를 확인하세요."
              exit 1
            fi
            echo "매니페스트 키 검증 통과 (jobs: ${count}개)"

      - name: Parse manifest into matrix
        id: parse
        uses: mikefarah/yq@v4
        with:
          cmd: |
            set -euo pipefail
            matrix="$(yq -o=json '.jobs' .ci/project.yml)"
            echo "파싱된 jobs:"
            echo "${matrix}" | python3 -m json.tool
            {
              echo "matrix<<'EOF'"
              echo "${matrix}"
              echo "EOF"
            } >> "$GITHUB_OUTPUT"

  test:
    needs: load-manifest
    runs-on: ${{ matrix.runs_on }}
    timeout-minutes: 30
    name: test / ${{ matrix.name }}

    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.load-manifest.outputs.matrix) }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Guardrails
        shell: bash
        run: |
          set -euo pipefail

          # runs_on allowlist
          case "${{ matrix.runs_on }}" in
            ubuntu-latest|windows-latest) ;;
            *) echo "::error::허용되지 않은 runs_on: ${{ matrix.runs_on }}"; exit 1 ;;
          esac

          # working_directory 경로 탈출 방지
          wd="${{ matrix.working_directory }}"
          if echo "$wd" | grep -q '\.\.'; then
            echo "::error::working_directory에 '..' 사용 금지: $wd"
            exit 1
          fi

          # working_directory 존재 확인
          if [ -n "$wd" ] && [ "$wd" != "." ] && [ ! -d "$wd" ]; then
            echo "::error::working_directory가 존재하지 않습니다: $wd"
            exit 1
          fi

          # build_tool allowlist
          case "${{ matrix.build_tool }}" in
            gradle|maven|pip|poetry|npm|pnpm|yarn) ;;
            *) echo "::error::허용되지 않은 build_tool: ${{ matrix.build_tool }}"; exit 1 ;;
          esac

          # runtime.language allowlist
          case "${{ matrix.runtime.language }}" in
            java|python|node) ;;
            *) echo "::error::허용되지 않은 language: ${{ matrix.runtime.language }} (java/python/node 중 하나)"; exit 1 ;;
          esac

          # Node 전용: cache 교차 오염 방지
          if [ "${{ matrix.runtime.language }}" = "node" ]; then
            case "${{ matrix.build_tool }}" in
              npm|yarn|pnpm) ;;
              *) echo "::error::Node build_tool은 npm/yarn/pnpm 중 하나: ${{ matrix.build_tool }}"; exit 1 ;;
            esac
          fi

      - name: Set up Java
        if: matrix.runtime.language == 'java'
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ matrix.runtime.version }}
          cache: ${{ matrix.build_tool }}

      - name: Set up Python
        if: matrix.runtime.language == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.runtime.version }}
          cache: pip

      - name: Set up Node
        if: matrix.runtime.language == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.runtime.version }}
          cache: ${{ matrix.build_tool }}

      - name: Install dependencies
        shell: bash
        run: |
          set -euo pipefail
          WORKDIR="${{ matrix.working_directory }}"
          INSTALL="${{ matrix.install_command }}"
          if [ -n "$WORKDIR" ] && [ "$WORKDIR" != "." ]; then
            cd "$WORKDIR"
          fi
          chmod +x ./gradlew 2>/dev/null || true
          if [ -n "${INSTALL:-}" ]; then
            echo "의존성 설치: $INSTALL"
            eval "$INSTALL"
          else
            echo "install_command 없음 — 건너뜀"
          fi

      - name: Run tests
        shell: bash
        run: |
          set -euo pipefail
          WORKDIR="${{ matrix.working_directory }}"
          TEST_CMD="${{ matrix.test_command }}"
          if [ -n "$WORKDIR" ] && [ "$WORKDIR" != "." ]; then
            cd "$WORKDIR"
          fi
          echo "테스트 실행: $TEST_CMD"
          eval "$TEST_CMD"
```

### 6-4. Guardrails 전체 목록 (v5)

CI가 자동으로 검증하는 항목들.

| 검증 항목 | 막는 문제 |
|-----------|-----------|
| 매니페스트 파일 존재 여부 | .ci/project.yml 없이 CI 실행 시도 |
| 필수 키 7개 누락/빈값 | 빈 값이 eval에서 애매한 에러로 나타나는 문제 |
| runs_on allowlist | 허용되지 않은 러너 사용 |
| working_directory .. 탈출 방지 | 경로 탈출 공격 |
| working_directory 실제 존재 확인 | 오타로 인한 조용한 실패 |
| build_tool allowlist | 잘못된 빌드 도구 지정 |
| runtime.language allowlist | 오타(jav, py 등)로 setup 스텝 조용히 스킵 |
| Node 전용 cache 교차 오염 방지 | Node job에 gradle/maven 등 잘못 지정 |

---

## 7. 문서 파일 시스템

### docs/plan.md 역할과 형식

모든 작업의 시작점. 승인 게이트. AI가 코드를 작성하기 전에 반드시 이 파일에 계획을 작성해야 한다.

```markdown
# 작업 계획서

## 목표
무엇을 만들 것인가

## 변경 파일
- src/main/java/.../AuthService.java
- src/main/java/.../AuthVO.java

## 리스크
어떤 사이드이펙트가 있을 수 있는가

## 대책
리스크를 어떻게 막을 것인가

## 순서
1. 첫 번째 수정
2. 두 번째 수정

상태: 승인 대기 중
```

### docs/checklist.md 역할

plan.md가 "이번 작업 계획"이라면, checklist.md는 "프로젝트 전체 진행 상태"다. 세션이 초기화되어도 어디까지 왔는지 알 수 있다.

```markdown
# 프로젝트 체크리스트

## 완료
- [x] Auth 로그인 API
- [x] JWT 토큰 발급

## 진행 중
- [ ] WebSocket 연결 관리

## 예정
- [ ] 결제 연동
```

### error_log.md 역할

이 파일이 세션 간 기억을 연결하는 핵심이다. `/clear`로 컨텍스트를 초기화해도 이 파일에 히스토리가 남아있어, 새 세션 시작 시 읽으면 과거 실수를 반복하지 않는다.

```markdown
## [2026-03-12]
- 도메인: Auth
- 문제: JWT 만료 시간이 설정값과 다르게 적용됨
- 원인: application.yml 키 이름 오타 (jwt.expiry vs jwt.expiration)
- 해결: 키 이름 통일
- 재발 방지: JWT 설정 키는 java-security-guide.md에 정답 명시
```

---

## 8. 실전 워크플로우

### 기능 1개 완성까지의 완전한 흐름

**Step 1: 세션 시작**
Cursor에서 새 대화 → "부트스트랩 실행해줘" 입력
AI가 plan.md, checklist.md, error_log.md를 읽고 각 1줄 요약 출력
요약이 보이지 않으면 실행하지 않은 것. 다시 요청.

**Step 2: 작업 지시**
"XXX 기능을 구현하고 싶은데 계획만 먼저 작성해줘. 코딩하지 마."
AI가 docs/plan.md에 계획서 작성
사람이 계획서 검토. 방향이 맞으면 "승인" 입력

**Step 3: 구현**
AI가 해당 도메인 스킬 파일 읽기 (Auth면 java-security-guide.md)
코딩 시작. 중간에 계획 충돌/범위 초과 발견 시 "[계획 충돌]" "[범위 초과]" 보고 후 멈춤
고위험 파일(Auth/Security/Transaction/Payment)은 파일별 diff 개별 확인

**Step 4: 검증**
정적 분석 실행 (경고 없으면 통과)
빌드 테스트 실행 (BUILD SUCCESS만 완료)
고위험 파일 변경이 있었으면 셀프 체크: 엣지 케이스 테스트 있는가?

**Step 5: 마무리**
error_log.md에 이번 세션 발생 에러 기록
checklist.md 업데이트
다음 기능 전에 /clear로 세션 초기화

### 복붙용 프롬프트 템플릿

**새 작업 시작용:**
```
다음 작업을 계획만 작성해줘. 코딩하지 마.
- 목표:
- 변경할 파일 후보:
- 핵심 로직:
- 리스크/사이드이펙트:
- 방지 대책:
plan.md에 반영하고 승인을 요청해.
작업 시작 전에 plan.md, checklist.md, error_log.md를 먼저 읽고 요약해.
```

**승인 후 구현용:**
```
계획 승인.
구현해줘. error_log.md에서 이 도메인 관련 과거 실수 있으면 먼저 확인하고 시작해.
Auth/Security/Transaction/Payment 관련 파일이면 Accept All 금지, 파일별 diff 개별 확인 전제로 변경해.
끝나면 ./gradlew clean test (Windows: .\gradlew.bat clean test) 실행하고
BUILD SUCCESS 확인 후 테스트 로그 일부 + checklist 업데이트까지 하고 완료 보고해.
```

---

## 9. 팩트 검증 기록

이 가이드는 Claude, Cursor, Gemini 세 AI가 서로의 제안을 검토하고 교차 검증한 결과다. 아래는 검증 과정에서 발견된 주요 오류와 수정 사항이다.

### Gemini에서 발견된 반복 버그

| 버그 | 내용 | 올바른 방법 |
|------|------|-------------|
| 트랜잭션 grep 오탐 | `save()`와 `@Transactional`은 항상 다른 줄에 있음. grep으로 같은 줄 검색 시 오탐 100% | 트랜잭션 검증은 테스트 코드로 담보 |
| heredoc 날짜 버그 | `<< 'EOF'` 홑따옴표 사용 시 `$(date)` 실행 안 됨 | `<< EOF` (따옴표 없이) |
| `-mmin -5` 오작동 | 세션 시작 시 항상 빈 결과 | Hooks에서 사용 부적합 |
| `/insight` 명령어 | Claude Code에 존재하지 않는 명령어 | 없는 명령어 |
| 5.5배 토큰 수치 | 비공식 출처, 팩트로 단정 불가 | "조건에 따라 다름"으로 표현 |

### Cursor가 지적한 Claude의 실수

| 실수 | 내용 |
|------|------|
| 자동 훅 과장 | "Ctrl+L로 CLAUDE.md 부트스트랩 자동 실행"처럼 표현. 실제로는 사람이 직접 입력해야 함 |
| matrix output 포맷 버그 | v2에서 `echo "k=v"` 방식으로 멀티라인 JSON 출력 시 깨짐. heredoc 방식으로 수정 |
| "강제력 없는 규칙은 규칙이 아니다" 과장 | 규칙도 유효함. 정확한 표현은 "강제력이 약하니 게이트로 보완하자" |

### 최종 채택 / 보류 정리

| 항목 | 결정 | 이유 |
|------|------|------|
| 확증 편향 감지 | 적용 | 계획 충돌 신호를 "조용히 무시"에서 "보고 이벤트"로 전환 |
| 범위 초과 감지 | 적용 | 파일 수정뿐 아니라 새 파일/리네임/의존성 추가도 포함 |
| 에러 루프 2회 멈춤 | 적용 | "동일한 에러" = 같은 테스트/같은 스택트레이스 핵심 |
| 확신도 태그 | 적용 (결정/위험 제안에만) | 모든 문장에 강제하면 대화 품질 저하 |
| 세션 20턴 경고 | 보류 | 20턴은 임의적. "대화가 길어졌다고 느껴지면"으로 완화 |
| 테스트 커버리지 체크 | 적용 (고위험에만) | 모든 작업 강제 시 과잉 비용 |
| Privacy Mode 단정 표현 | 수정 | "학습 사용 최소화 목적"으로 이해가 정확 |

---

## 10. Branch Protection 설정 가이드

**이것이 "마지막 1단계"다.** ci.yml 파일을 올려도 이 설정이 없으면 CI 실패해도 머지가 가능하다.

### 설정 경로

```
GitHub 레포 → Settings → Branches → Branch protection rules
→ Add branch ruleset 또는 Add rule
```

### 설정 항목

```
Branch name pattern: main (또는 master)

✅ Require a pull request before merging
✅ Require status checks to pass before merging
   → Status checks that are required:
      "test / backend-java"    ← .ci/project.yml의 job name 그대로
      "test / realtime-python" ← 여러 job이면 전부 추가

✅ Require pull request reviews (권장)
✅ Do not allow bypassing the above settings
```

### 체크 이름 확인 방법

ci.yml의 이 줄에서 결정된다:
```yaml
name: test / ${{ matrix.name }}
```
`.ci/project.yml`의 `name` 값이 `backend-java`면 체크 이름은 `test / backend-java`.

---

## 11. 완성 체크리스트

### 로컬 설정

- [ ] `.cursorignore` 프로젝트 루트에 추가
- [ ] `.cursorrules` 프로젝트 루트에 추가
- [ ] `~/.claude/CLAUDE.md` 전역 파일 생성
- [ ] `CLAUDE.md` 프로젝트 루트에 생성
- [ ] `error_log.md` 생성 (빈 파일로 시작)
- [ ] `docs/plan.md` 생성
- [ ] `docs/checklist.md` 생성
- [ ] `.claude/skills/` 디렉토리 생성
- [ ] Cursor Privacy Mode 활성화
- [ ] Cursor Spend Limit 설정
- [ ] Read-Only DB 계정 설정 (강력 권장)

### CI 설정

- [ ] `.ci/project.yml` 프로젝트에 맞게 작성
- [ ] `.github/workflows/ci.yml` 레포에 추가 (수정 없이 그대로)
- [ ] GitHub에 푸시
- [ ] GitHub Settings → Branches → Branch protection rules 설정
- [ ] `test / {job name}` 필수 체크로 지정

### 운영 확인

- [ ] PR 생성 시 CI 자동 실행 확인
- [ ] 테스트 실패 시 머지 불가 확인
- [ ] 세션 시작 시 부트스트랩 출력 확인
- [ ] plan.md 승인 없이 코드 수정 안 되는지 확인

---

## 최종 한 줄 결론

**로컬(Cursor/Claude Code)은 게이트/문서/검증 루프로 AI 실패를 막고, GitHub CI는 테스트 실패를 서버에서 구조적으로 차단한다. 두 계층이 합쳐질 때 이 시스템이 완성된다.**

