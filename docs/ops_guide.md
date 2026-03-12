# 운영 가이드 (사람용 규칙)

## 새 팀원 온보딩 순서 (이 순서로 읽고 설정)

1. `FINAL_COMPLETE_GUIDE.md` — 전체 철학과 구조 파악 (30분)
2. `.cursorrules` 복붙 → 프로젝트 루트에 배치되어 있는지 확인
3. `.ci/project.yml` 환경에 맞게 수정
4. GitHub Branch Protection 설정 확인
5. 로컬에서 테스트 1회 실행해서 BUILD SUCCESS 확인
6. `error_log.md`, `docs/plan.md`, `docs/checklist.md` 존재 확인

이 6단계가 끝나야 첫 작업을 시작할 수 있다.

## mutable / immutable

**바꿔도 되는 것 (mutable)**  
- `.ci/project.yml`  
- `.claude/skills/` 디렉토리 내 스킬 파일  
- `docs/high_risk_areas.md`  
- `docs/plan.md` 양식 (섹션 추가·수정 가능, 단 "목표/변경 파일/리스크/대책/순서/상태" 의미는 유지)

**절대 바꾸지 않는 것 (immutable)**  
- `.github/workflows/ci.yml`  
- `.cursorrules`의 코어 방어선 6개  
  - 계획 게이트  
  - 고위험 파일 게이트  
  - 에러 루프 감지  
  - 범위 초과 감지  
  - 계획 충돌 감지  
  - 확신도 태그 규칙

## 멀티 브랜치 운영

- **브랜치 전환 전**  
  - 현재 브랜치의 `docs/plan.md`에서 상태를 `"보류"`로 변경하고,  
    왜 중단하는지 간단한 메모를 남긴다.
- **브랜치 복귀 시**  
  - 해당 브랜치의 `docs/plan.md` 상태를 확인하고,  
    "보류"였던 계획을 검토한 뒤 다시 "승인 대기"/"진행 중" 등으로 변경하고 작업을 재개한다.
