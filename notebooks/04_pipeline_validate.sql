-- Lakeflow Job의 SQL file task에서 실행하는 파이프라인 검증 쿼리
-- 선행 Pipeline task가 성공한 뒤 SQL Warehouse에서 실행합니다.
-- actual은 실제 행 수, expected는 제공 샘플 전체를 적재했을 때의 기대 행 수입니다.
-- 추가 데이터를 넣었다면 아래 기대값도 그 데이터에 맞춰 판단해야 합니다.
-- FAIL은 결과 문자열입니다. 이 쿼리는 FAIL이 나와도 SQL 오류로 Job을 중단시키지 않습니다.
-- Task의 Succeeded 표시와 별도로 세 결과가 모두 PASS인지 확인합니다.

SELECT
  object_name,
  actual,
  expected,
  CASE WHEN actual = expected THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  -- UNION ALL로 Bronze·Silver·Gold의 검증 결과를 한 표에 모읍니다.
  SELECT 'bronze_orders' AS object_name, COUNT(*) AS actual, 300 AS expected
  FROM cafe_training.cafe_hands_on.bronze_orders
  UNION ALL
  SELECT 'silver_orders_clean', COUNT(*), 296
  FROM cafe_training.cafe_hands_on.silver_orders_clean
  UNION ALL
  SELECT 'gold_sales', COUNT(*), 266
  FROM cafe_training.cafe_hands_on.gold_sales
);
