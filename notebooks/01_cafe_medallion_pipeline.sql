-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01. 카페 메달리온 Lakeflow Pipeline
-- MAGIC
-- MAGIC 이 노트북은 일반 SQL 노트북이 아니라 **Lakeflow Spark Declarative Pipelines 소스**로 등록합니다.
-- MAGIC 한 파일 안에서 Bronze → Silver → Gold 의존성을 선언하면 Lakeflow가 DAG와 실행 순서를 자동 구성합니다.
-- MAGIC
-- MAGIC **사전 준비:** 00 Setup과 CSV 업로드를 마치고, Pipeline의 출력 위치를 `cafe_training.cafe_hands_on`으로 지정합니다.
-- MAGIC **흐름:** Bronze는 원본 적재, Silver는 타입·중복·품질 정리, Gold는 완료 주문의 매출 분석입니다.
-- MAGIC **제공 샘플의 예상 주문 수:** Bronze 300행 → Silver 296행 → Gold 266행.
-- MAGIC 새 파일 없이 일반 갱신을 다시 실행하면 증분 입력이 0일 수 있습니다. 전체 결과는 검증 SQL로 확인합니다.

-- COMMAND ----------

-- Bronze: 새로 발견한 파일을 증분으로 읽고 원본 컬럼에 추적용 정보를 덧붙입니다.
-- CREATE OR REFRESH는 Pipeline이 유지할 데이터셋과 갱신 로직을 선언합니다.
CREATE OR REFRESH STREAMING TABLE bronze_stores
COMMENT '원본 CSV를 변경 없이 증분 적재한 매장 Bronze 테이블'
-- quality는 계층을 표시하는 속성입니다. 이 속성만으로 품질 검사가 실행되지는 않습니다.
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  -- 문제 행의 원본 파일과 적재 시각을 추적할 수 있도록 남깁니다.
  _metadata.file_path AS _source_file,
  current_timestamp() AS _ingested_at
FROM STREAM read_files(
  -- Streaming read_files는 파일 경로 대신 디렉터리 또는 glob 경로를 사용합니다.
  '/Volumes/cafe_training/cafe_landing/raw/stores*.csv',
  format => 'csv',
  -- 첫 행을 컬럼명으로 사용하고, 값은 문자열로 읽어 Silver에서 타입을 정합니다.
  header => 'true',
  inferColumnTypes => 'false'
);

-- COMMAND ----------

-- 상품 기준정보도 같은 방식으로 적재합니다. Gold에서 상품명·카테고리를 붙일 때 씁니다.
CREATE OR REFRESH STREAMING TABLE bronze_products
COMMENT '원본 CSV를 변경 없이 증분 적재한 상품 Bronze 테이블'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  _metadata.file_path AS _source_file,
  current_timestamp() AS _ingested_at
FROM STREAM read_files(
  -- Streaming read_files는 파일 경로 대신 디렉터리 또는 glob 경로를 사용합니다.
  '/Volumes/cafe_training/cafe_landing/raw/products*.csv',
  format => 'csv',
  header => 'true',
  inferColumnTypes => 'false'
);

-- COMMAND ----------

-- 주문은 orders 폴더의 CSV 배치를 읽습니다. 파일 증분 적재와 주문 ID 중복 제거는 별개입니다.
CREATE OR REFRESH STREAMING TABLE bronze_orders
COMMENT '3개 CSV 배치를 Auto Loader로 증분 적재한 주문 Bronze 테이블'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  _metadata.file_path AS _source_file,
  current_timestamp() AS _ingested_at
FROM STREAM read_files(
  '/Volumes/cafe_training/cafe_landing/raw/orders',
  format => 'csv',
  header => 'true',
  inferColumnTypes => 'false'
);

-- COMMAND ----------

-- Silver: 정리한 조회 결과를 저장·갱신하는 Materialized View입니다.
-- EXPECT는 행별 품질 조건, ON VIOLATION DROP ROW는 조건 위반 행을 결과에서 제외하는 정책입니다.
CREATE OR REFRESH MATERIALIZED VIEW silver_stores (
  CONSTRAINT valid_store_id EXPECT (store_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_store_name EXPECT (store_name IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT '타입과 필수값을 정리한 매장 Silver 테이블'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  -- TRIM: 앞뒤 공백 제거 / TRY_CAST: 변환할 수 없는 값은 오류 대신 NULL 반환
  TRIM(store_id) AS store_id,
  TRIM(store_name) AS store_name,
  TRIM(region) AS region,
  TRY_CAST(opened_date AS DATE) AS opened_date
FROM bronze_stores;

-- COMMAND ----------

-- 상품 ID와 양수 가격 조건을 확인합니다. 기대 조건은 타입을 정리한 출력값에 적용됩니다.
CREATE OR REFRESH MATERIALIZED VIEW silver_products (
  CONSTRAINT valid_product_id EXPECT (product_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT positive_list_price EXPECT (list_price > 0) ON VIOLATION DROP ROW
)
COMMENT '타입과 필수값을 정리한 상품 Silver 테이블'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  TRIM(product_id) AS product_id,
  TRIM(product_name) AS product_name,
  TRIM(category) AS category,
  TRY_CAST(list_price AS INT) AS list_price
FROM bronze_products;

-- COMMAND ----------

-- 취소 주문도 유효한 상태로 보존합니다. 매출에서 제외하는 단계는 아래 Gold입니다.
-- 샘플 300행에서 중복 2행과 품질 조건 위반 2행을 제외하면 296행이 남습니다.
CREATE OR REFRESH MATERIALIZED VIEW silver_orders_clean (
  CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_order_ts EXPECT (order_ts IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT positive_quantity EXPECT (quantity > 0) ON VIOLATION DROP ROW,
  CONSTRAINT positive_unit_price EXPECT (unit_price > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_discount EXPECT (discount_pct BETWEEN 0 AND 100) ON VIOLATION DROP ROW,
  CONSTRAINT valid_status EXPECT (status IN ('COMPLETED', 'CANCELLED')) ON VIOLATION DROP ROW
)
COMMENT '배치 간 중복 제거, 타입 변환, NULL과 상태값을 표준화한 주문 Silver 테이블'
TBLPROPERTIES ('quality' = 'silver')
AS
-- CTE(이름 붙인 중간 쿼리)로 타입 변환 → 중복 제거 단계를 나누어 읽습니다.
WITH typed AS (
  SELECT
    TRIM(order_id) AS order_id,
    TRY_CAST(order_ts AS TIMESTAMP) AS order_ts,
    TRIM(store_id) AS store_id,
    TRIM(product_id) AS product_id,
    TRY_CAST(quantity AS INT) AS quantity,
    TRY_CAST(unit_price AS INT) AS unit_price,
    -- 할인율이 비었거나 숫자로 변환되지 않으면 0으로 처리하는 이 실습의 규칙입니다.
    -- 0D는 DOUBLE 타입의 0이며, COALESCE는 처음으로 NULL이 아닌 값을 선택합니다.
    COALESCE(TRY_CAST(discount_pct AS DOUBLE), 0D) AS discount_pct,
    -- " completed " 같은 입력을 "COMPLETED"로 통일합니다.
    UPPER(TRIM(status)) AS status,
    _source_file,
    _ingested_at
  FROM bronze_orders
),
deduplicated AS (
  -- order_id마다 파일 경로·적재 시각 오름차순으로 첫 행을 선택합니다.
  -- 최신 주문 시각을 선택하는 규칙은 아닙니다. 동률이면 선택 순서가 보장되지 않습니다.
  SELECT *
  FROM typed
  -- ROW_NUMBER는 그룹 안의 순번, QUALIFY는 계산된 순번을 조건으로 행을 거릅니다.
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id
    ORDER BY _source_file, _ingested_at
  ) = 1
)
SELECT * FROM deduplicated;

-- COMMAND ----------

-- Gold: 완료 주문에 매장·상품 정보를 붙이고 매출 분석에 쓸 값을 계산합니다.
CREATE OR REFRESH MATERIALIZED VIEW gold_sales
-- 저장 데이터의 클러스터링 키를 자동 선택하도록 설정합니다.
CLUSTER BY AUTO
COMMENT '완료 주문을 매장·상품과 결합하고 분석 파생값을 계산한 Gold 매출 테이블'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  o.order_id,
  o.order_ts,
  CAST(o.order_ts AS DATE) AS order_date,
  HOUR(o.order_ts) AS order_hour,
  -- DAYOFWEEK의 일요일=1, 토요일=7을 한글 요일과 평일/주말로 바꿉니다.
  CASE DAYOFWEEK(o.order_ts)
    WHEN 1 THEN '일'
    WHEN 2 THEN '월'
    WHEN 3 THEN '화'
    WHEN 4 THEN '수'
    WHEN 5 THEN '목'
    WHEN 6 THEN '금'
    WHEN 7 THEN '토'
  END AS day_name,
  CASE WHEN DAYOFWEEK(o.order_ts) IN (1, 7) THEN '주말' ELSE '평일' END AS day_type,
  -- 시간 구간을 업무상 이름으로 묶습니다. BETWEEN의 양끝 시간도 포함됩니다.
  CASE
    WHEN HOUR(o.order_ts) BETWEEN 6 AND 10 THEN '모닝'
    WHEN HOUR(o.order_ts) BETWEEN 11 AND 13 THEN '점심'
    WHEN HOUR(o.order_ts) BETWEEN 14 AND 17 THEN '오후'
    WHEN HOUR(o.order_ts) BETWEEN 18 AND 21 THEN '저녁'
    ELSE '야간'
  END AS daypart,
  o.store_id,
  s.store_name,
  s.region,
  o.product_id,
  p.product_name,
  p.category,
  o.quantity,
  o.unit_price,
  o.discount_pct,
  -- 총매출 = 수량 × 단가 / 할인액 = 총매출 × 할인율 / 순매출 = 총매출 - 할인액
  o.quantity * o.unit_price AS gross_sales,
  o.quantity * o.unit_price * o.discount_pct / 100D AS discount_amount,
  o.quantity * o.unit_price * (1D - o.discount_pct / 100D) AS net_sales
FROM silver_orders_clean o
-- INNER JOIN이므로 기준정보에 매장·상품 ID가 없는 주문은 여기서 제외됩니다.
INNER JOIN silver_stores s USING (store_id)
INNER JOIN silver_products p USING (product_id)
-- 샘플의 취소 주문 30건을 제외한 266건이 매출 계산 대상입니다.
WHERE o.status = 'COMPLETED';
