# Java Security 실수 방지 패턴

## 패턴 1: 암호화 컬럼 검색
- 상황: EMAIL, PHONE 검색 시 일치하지 않음
- 원인: AES-256 암호화된 원본 컬럼으로 비교 시도
- 해결: SHA-256 해시 컬럼(EMAIL_HASH, PHONE_HASH)으로 검색
- 확인:
  ```java
  // 틀린 방법
  userRepository.findByEmail(email);

  // 올바른 방법
  String emailHash = HashUtil.generateHash(email);
  userRepository.findByEmailHash(emailHash);
  ```

## 패턴 2: JWT 설정 키 이름
- 상황: JWT 토큰이 만료 후에도 유효하게 처리됨
- 원인: application.yml 키 이름 오타
- 해결: jwt.expiration 사용 (jwt.expiry 아님)
- 확인:
  ```yaml
  jwt:
    expiration: 86400000  # 올바름
    # expiry: 86400000   # 틀림
  ```

## 패턴 3: @Transactional 검증
- 상황: @Transactional이 제대로 동작하는지 확인하려 함
- 원인: grep으로 확인 시 오탐 발생
- 해결: 테스트 코드로만 검증
- 확인: grep 절대 사용 금지

## 패턴 4: 임시 비밀번호 발급
- 상황: 임시 비밀번호 발급 후 PW_CHANGE_REQUIRED 미설정
- 원인: 플래그 업데이트 누락
- 해결: 임시 비밀번호 저장 시 PW_CHANGE_REQUIRED='Y' 동시 업데이트
- 확인:
  ```java
  user.setUserPw(encodedTempPw);
  user.setPwChangeRequired("Y");  // 반드시 함께
  userRepository.save(user);
  ```

## 패턴 5: Rate Limiter IP 추출
- 상황: 프록시 뒤에서 IP 차단이 우회됨
- 원인: X-Forwarded-For 헤더를 보안 판단에 사용
- 해결: 보안 판단용은 직접 연결 IP만 사용
- 확인:
  ```java
  // 보안 판단용 (Rate Limiter)
  String ip = IpUtil.getRateLimitIp(request); // X-Forwarded-For 무시

  // 로그용
  String ip = IpUtil.getClientIp(request); // 프록시 고려
  ```

## 패턴 6: 민감정보 로그 출력
- 상황: 이메일/전화번호/비밀번호가 로그에 남음
- 원인: 디버깅 중 log.info()에 원본값 포함
- 해결: 마스킹 후 출력 또는 로그에서 완전 제거
- 확인:
  ```java
  // 틀린 방법
  log.info("User email: {}", user.getEmail());

  // 올바른 방법
  log.info("User email: {}", MaskingUtil.maskEmail(user.getEmail()));
  ```

## 패턴 7: DB 스키마 변경
- 상황: 운영 DB에서 컬럼이 사라지거나 타입이 바뀜
- 원인: hibernate.ddl-auto=update 사용
- 해결: Flyway 마이그레이션 스크립트 사용
- 확인:
  ```yaml
  # 운영 환경 절대 금지
  spring.jpa.hibernate.ddl-auto: update

  # 올바른 방법
  spring.jpa.hibernate.ddl-auto: validate
  # + Flyway V1__description.sql 작성
  ```
