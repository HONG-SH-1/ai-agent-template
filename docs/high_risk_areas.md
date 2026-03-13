# High Risk Areas

## 고위험 도메인
- Auth / Security / Transaction / Payment

## 실제 경로 (프로젝트마다 여기에 추가)
# 예시:
# src/main/java/com/example/service/AuthService.java
# src/main/java/com/example/security/

## 적용 규칙
위 경로 파일 수정 시:
- Accept All 절대 금지
- 파일별 diff 개별 승인만
- 메서드/블록 단위 수정만
- 완료 후 null/빈값/권한 없는 사용자 테스트 확인
