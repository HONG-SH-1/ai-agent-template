# AI 에이전트 방어 시스템 템플릿

> Claude.ai + Cursor Pro + Claude Code를 활용한
> **3단 방어 레이어 기반 개인 백엔드 개발 환경**

---

## 이 시스템이 막는 것

| 실패 유형 | 대응 |
|-----------|------|
| 테스트 없이 완료 선언 | CI + Branch Protection |
| 계획 없이 대량 파일 수정 | plan.md 승인 게이트 |
| 고위험 파일 Accept All | .cursor/rules/high-risk-files.mdc |
| 같은 에러 반복 수정 | 에러 루프 감지 |
| 세션 초기화 후 실수 반복 | error_log.md 세션 간 기억 |
| 민감정보 하드코딩 | 정적 분석 check.sh |
| CI 실패해도 머지 | Branch Protection |

---

## 3단 방어 레이어

```
1계층 (로컬 IDE)
├── .cursor/rules/general.mdc          ← 기본 규칙 (항상 적용)
├── .cursor/rules/high-risk-files.mdc  ← 고위험 파일 감지 시 동적 적용
├── .cursor/rules/java-security.mdc    ← Java 파일 작업 시 동적 적용
├── .cursorrules                        ← 경량 전역 규칙
└── .cursorignore                       ← AI 시야 차단

2계층 (작업 메모리)
├── docs/plan.md                        ← 계획 + 승인 게이트
├── docs/checklist.md                   ← 전체 진행 상태
├── docs/high_risk_areas.md             ← 고위험 파일 경로
├── error_log.md                        ← 세션 간 실수 기억
└── .claude/skills/                     ← 영구 도메인 지식

3계층 (서버)
├── .ci/project.yml                     ← 테스트 환경 정의
├── .github/workflows/ci.yml            ← 자동 테스트
└── GitHub Branch Protection            ← 실패 시 머지 차단
```

---

## 도구별 역할

| 도구 | 역할 | 규칙 파일 |
|------|------|-----------|
| **Claude.ai** | 설계/승인 게이트 | 인수인계서 |
| **Cursor Pro** | 코드 수정 + diff 확인 | .cursor/rules/*.mdc |
| **Claude Code** | 일반 로직 자율 구현 + 테스트 | CLAUDE.md |
| **check.sh** | 정적 분석 + 테스트 자동화 | — |

---

## 매일 작업 흐름

```
1. Cursor 부트스트랩
   → plan/checklist/error_log/high_risk_areas 읽기

2. Claude.ai에서 설계/계획 논의

3. Cursor에서 plan.md 작성

4. Claude.ai 승인

5. 구현
   ├── 일반 로직: Claude Code 자율 루프 허용
   └── 고위험 파일: Cursor + diff 개별 확인 필수

6. 검증
   ./check.sh [working_directory]

7. 정리
   checklist.md + error_log.md 업데이트 → /clear

8. PR → GitHub CI → Branch Protection → 머지
```

---

## 새 프로젝트 시작하기

### Step 1: 템플릿 복제
```
GitHub → ai-agent-template → Use this template
```

### Step 2: 로컬 Clone
```bash
git clone https://github.com/[계정]/[새프로젝트].git
cd [새프로젝트]
```

### Step 3: 프로젝트 설정 (필수 수정 파일)

```
.ci/project.yml              ← 언어/버전/테스트 명령어
docs/high_risk_areas.md      ← 실제 고위험 파일 경로
.cursorrules                 ← [담당 폴더 경로] 채우기
```

### Step 4: 팀 프로젝트인 경우
```bash
# 개인 설정 파일을 GitHub에 올리지 않도록 보호
Add-Content .git/info/exclude ".cursorrules"
Add-Content .git/info/exclude ".cursorignore"
Add-Content .git/info/exclude "CLAUDE.md"
Add-Content .git/info/exclude "error_log.md"
Add-Content .git/info/exclude ".ci/"
Add-Content .git/info/exclude ".claude/"
Add-Content .git/info/exclude "docs/plan.md"
Add-Content .git/info/exclude "docs/checklist.md"
Add-Content .git/info/exclude "docs/high_risk_areas.md"
```

### Step 5: GitHub Branch Protection 설정
```
Settings → Branches → Add rule
Branch: main
✅ Require status checks to pass
Status check: test / [project.yml의 name값]
```

### Step 6: 전역 규칙 설정 (컴퓨터마다 1회)
```bash
New-Item -ItemType Directory -Force -Path "$HOME\.claude"
# 내용은 docs/GLOBAL_CLAUDE_TEMPLATE.md 참조
```

---

## 파일 구조

```
프로젝트/
├── .cursor/
│   └── rules/
│       ├── general.mdc          ← 기본 규칙 (항상 적용)
│       ├── high-risk-files.mdc  ← 고위험 파일 감지 시 적용
│       └── java-security.mdc   ← Java 작업 시 적용
├── .cursorrules                 ← 경량 전역 규칙
├── .cursorignore                ← AI 시야 차단
├── CLAUDE.md                    ← Claude Code 세션 규칙
├── check.sh                     ← 정적분석 + 테스트 자동화
├── error_log.md                 ← 세션 간 실수 기억
├── .ci/
│   └── project.yml              ← 테스트 환경 (프로젝트마다 수정)
├── .github/
│   └── workflows/
│       └── ci.yml               ← CI 게이트 (수정 금지)
├── .claude/
│   └── skills/
│       ├── java-security-guide.md    ← Java 보안 패턴 축적
│       └── python-websocket-guide.md
└── docs/
    ├── plan.md                  ← 현재 작업 계획
    ├── checklist.md             ← 전체 진행 상태
    ├── high_risk_areas.md       ← 고위험 파일 경로
    ├── ops_guide.md             ← 운영 규칙
    ├── error-log-gc-guide.md    ← error_log 가비지 컬렉션 기준
    └── FINAL_COMPLETE_GUIDE.md  ← 설계 원칙 전체
```

---

## 수정해도 되는 것 vs 금지

| 구분 | 파일 |
|------|------|
| ✅ 프로젝트마다 수정 | .ci/project.yml, docs/high_risk_areas.md, .cursorrules의 작업 범위 |
| ⚠️ 조심히 수정 | .cursor/rules/*.mdc, CLAUDE.md |
| 🚫 절대 수정 금지 | .github/workflows/ci.yml |

---

## 시스템 한계

1. `.cursor/rules/*.mdc`는 강제력 없음 — 사람이 diff 확인 필수
2. Branch Protection도 관리자는 우회 가능
3. check.sh 통과 ≠ 올바른 코드 (TDD 보강 필요)
4. Claude Code 자율 루프 중 고위험 파일 수정 위험 존재
   → CLAUDE.md에 금지 명시로 보완 (완전한 락은 아님)

---

## 토스 지원서용 한 줄 요약

> "Claude.ai + Cursor Pro + Claude Code를 활용해
> 3단 방어 레이어(로컬 규칙 / 작업 메모리 / 서버 강제력) 기반
> AI 에이전트 방어 시스템을 설계하고 실제 프로젝트에 적용했습니다."

---

## 참고

- 제미나이 3개 AI 교차 검증 완료
- 실제 적용 프로젝트: Ai-Law (법률 AI 서비스)
- 완성도 평가: 85/100 (제미나이 평가, 2026.03)
