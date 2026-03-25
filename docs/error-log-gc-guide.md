# error_log.md 가비지 컬렉션 기준

## 언제 가비지 컬렉션을 하는가
- error_log.md가 50줄을 넘을 때
- 같은 도메인 에러가 3회 이상 쌓였을 때
- 새 프로젝트 시작 전

## 가비지 컬렉션 절차

### 1단계: 분류
error_log.md의 각 항목을 아래로 분류:
- 해결됨 + 재발 가능성 높음 → skills 승격 대상
- 해결됨 + 일회성 실수    → 삭제 대상
- 미해결                  → 유지

### 2단계: skills 승격
재발 가능성 높은 항목은 .claude/skills/ 파일로 이동.

형식:
```
# [도메인] 실수 방지 패턴

## 패턴 1: [제목]
- 상황: 언제 발생하는가
- 원인: 왜 발생하는가
- 해결: 어떻게 해결하는가
- 확인: 올바른 코드 예시
```

예시:
JWT 설정 오타 → java-security-guide.md에 추가
AES-256 복호화 실패 → java-security-guide.md에 추가

### 3단계: 삭제
승격하거나 일회성인 항목은 error_log.md에서 제거.

### 4단계: error_log.md 상단에 기록
```
## [가비지 컬렉션 완료: YYYY-MM-DD]
- 승격: X개 항목 → java-security-guide.md
- 삭제: Y개 항목 (해결된 일회성 에러)
- 유지: Z개 항목
```

## skills 파일 목록
- .claude/skills/java-security-guide.md
- .claude/skills/python-websocket-guide.md
- (프로젝트마다 추가)
