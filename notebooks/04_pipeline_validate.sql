-- Lakeflow Job의 SQL file task에서 실행하는 파이프라인 검증 쿼리
-- 선행 Pipeline task가 성공한 뒤 SQL Warehouse에서 실행합니다.
-- Lakeflow Jobs의 Task 성공은 SQL 실행 성공을 뜻합니다. 결과의 FAIL은 자동 실패로 처리되지 않습니다.
-- 제공 CSV 기준으로 세 행이 모두 PASS인지 확인합니다.

SELECT
  object_name,
  actual,
  expected,
  CASE WHEN actual = expected THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT 'bronze_orders' AS object_name, COUNT(*) AS actual, 300 AS expected
  FROM cafe_training.cafe_hands_on.bronze_orders
  UNION ALL
  SELECT 'silver_orders_clean', COUNT(*), 296
  FROM cafe_training.cafe_hands_on.silver_orders_clean
  UNION ALL
  SELECT 'gold_sales', COUNT(*), 266
  FROM cafe_training.cafe_hands_on.gold_sales
);
