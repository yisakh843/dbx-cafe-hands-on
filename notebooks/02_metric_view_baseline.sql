-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02. Metric View 기준선 생성
-- MAGIC
-- MAGIC Unity Catalog Metric View에 분석 기준과 지표 계산식을 정의해 SQL·Genie에서 재사용합니다.
-- MAGIC 다음 03 노트북에서 같은 Metric View에 설명·동의어·표시 형식을 추가합니다.

-- COMMAND ----------

CREATE OR REPLACE VIEW cafe_training.cafe_hands_on.cafe_sales_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1
# source: 읽을 원천 데이터
source: cafe_training.cafe_hands_on.gold_sales

# fields: 매장·날짜 등 그룹화하거나 필터링할 기준
fields:
  # name: 조회할 이름 / expr: 원천 컬럼 또는 계산식
  - name: order_date
    expr: order_date
  - name: day_name
    expr: day_name
  - name: day_type
    expr: day_type
  - name: daypart
    expr: daypart
  - name: store_name
    expr: store_name
  - name: region
    expr: region
  - name: product_name
    expr: product_name
  - name: category
    expr: category

# measures: 합계·개수·비율 등 계산할 지표
measures:
  - name: gross_sales
    expr: SUM(gross_sales)
  - name: discount_amount
    expr: SUM(discount_amount)
  - name: net_sales
    expr: SUM(net_sales)
  - name: order_count
    expr: COUNT(DISTINCT order_id)
  - name: item_quantity
    expr: SUM(quantity)
  - name: avg_order_value
    expr: SUM(net_sales) / COUNT(DISTINCT order_id)
$$;

-- COMMAND ----------

-- 전체 지표 확인: 순매출 1,734,580원 / 주문수 266건 / 객단가 약 6,520.98원
SELECT
  MEASURE(net_sales) AS net_sales,
  MEASURE(order_count) AS order_count,
  MEASURE(avg_order_value) AS avg_order_value
FROM cafe_training.cafe_hands_on.cafe_sales_metrics;
