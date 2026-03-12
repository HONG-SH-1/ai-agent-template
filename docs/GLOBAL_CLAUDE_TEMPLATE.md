# Global CLAUDE.md 템플릿 (~/.claude/CLAUDE.md)

이 파일 내용 전체를 로컬 홈 디렉토리의 `~/.claude/CLAUDE.md` 로 복사하면,
Claude Code가 어떤 프로젝트에서든 전역으로 적용된다.

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

