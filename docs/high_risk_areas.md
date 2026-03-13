# High Risk Areas

## Auth
Backend-main/src/main/java/com/example/backend_main/HSH/service/AuthService.java
Backend-main/src/main/java/com/example/backend_main/common/security/JwtAccessDeniedHandler.java
Backend-main/src/main/java/com/example/backend_main/common/security/JwtAuthenticationEntryPoint.java
Backend-main/src/main/java/com/example/backend_main/common/security/SecurityMonitorService.java

## Payment
Backend-main/src/main/java/com/example/backend_main/ky/service/PaymentService.java

## 적용 규칙
위 경로 파일 수정 시:
- Accept All 절대 금지
- 파일별 diff 개별 승인만
- 메서드/블록 단위 수정만
- 완료 후 null/빈값/권한 없는 사용자 테스트 확인