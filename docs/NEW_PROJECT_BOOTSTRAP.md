# 새 프로젝트 부트스트랩 가이드

이 레포(Ai-Law)를 기준 템플릿으로 사용해,
새 프로젝트에 동일한 3단 방어 레이어를 설치하는 절차.

## 1. GitHub 템플릿 레포로 만들기

1. GitHub에서 이 레포를 연다.
2. Settings → General → "Template repository" 체크.
3. 저장.

이제 새 레포를 만들 때 "Use this template"을 선택하면,
현재 파일 구조 전체가 복사된다.

## 2. 새 프로젝트 생성 후 필수 수정 항목

템플릿에서 새 레포를 만든 뒤, 최소한 다음만 프로젝트에 맞게 수정한다.

- `.ci/project.yml`
  - `name`: 새 서비스 이름
  - `runtime.version`: 실제 사용하는 언어 버전
  - `build_tool` / `test_command`: Gradle, npm 등으로 바꿀 경우 여기를 조정
- `docs/high_risk_areas.md`
  - 실제 패키지/디렉토리 경로를 채워 넣어 고위험 도메인을 구체화
- `.claude/skills/` 내부 파일
  - 도메인 실수가 쌓이면 error_log.md에서 내용을 승격하여 채워 넣기

나머지 파일(`.cursorrules`, `.github/workflows/ci.yml`, `docs/FINAL_COMPLETE_GUIDE.md` 등)은
가능한 한 그대로 사용한다.

## 3. 전역 CLAUDE.md 설정 (한 번만)

1. 이 레포의 `docs/GLOBAL_CLAUDE_TEMPLATE.md`를 연다.
2. 안에 있는 내용을 그대로 복사한다.
3. 로컬 머신에 `~/.claude/` 디렉토리가 없다면 만든다.
4. `~/.claude/CLAUDE.md` 파일을 만들고 붙여넣는다.

이렇게 하면 Claude Code는 어떤 프로젝트에서든:
- error_log.md / docs/checklist.md를 세션 초기에 읽고,
- 승인 없이 코드 수정하지 않고,
- 테스트 없이 완료 선언하지 않는 전역 규칙을 따른다.

