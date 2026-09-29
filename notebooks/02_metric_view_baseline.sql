-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02. Metric View 기준선 생성
-- MAGIC
-- MAGIC 이 노트북은 **`cafe_sales_metrics`라는 Metric View 하나**를 만듭니다.
-- MAGIC 앞에서 만든 `gold_sales`를 읽어, **무엇을 기준으로 나눠 보고 어떤 공식으로 계산할지** 정의합니다.
-- MAGIC
-- MAGIC **기준선**은 기본 계산 정의만 넣은 첫 버전입니다. 다음 `03_metric_view_optimized.sql`에서는 같은 Metric View에 설명·표시명·동의어·포맷·Materialization을 추가합니다.
-- MAGIC
-- MAGIC ## 아래 YAML 읽는 법
-- MAGIC
-- MAGIC | 항목 | 의미 | 이 실습의 내용 |
-- MAGIC |---|---|---|
-- MAGIC | `source` | 읽을 데이터 | 완료 주문과 매장·상품 정보가 담긴 `gold_sales` |
-- MAGIC | `fields` | 나눠 보거나 필터링할 기준 | 주문일·요일·평일/주말·시간대·매장·지역·상품·카테고리 8개 |
-- MAGIC | `measures` | 계산할 지표 | 총매출·할인액·순매출·주문수·판매수량·객단가 6개 |
-- MAGIC
-- MAGIC 예를 들어 **“매장별 순매출”**은 `store_name`으로 나눠 `net_sales`에 정의된 합계를 계산한다는 뜻입니다.
-- MAGIC `name`은 조회할 때 쓸 이름, `expr`은 가져올 컬럼이나 계산식입니다.

-- COMMAND ----------

CREATE OR REPLACE VIEW cafe_training.cafe_hands_on.cafe_sales_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1
# 원천: 2부에서 만든 완료 주문 데이터
source: cafe_training.cafe_hands_on.gold_sales

# 분석 기준 8개: 날짜·매장·상품 등으로 나누거나 필터링할 때 사용
fields:
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

# 지표 6개: 선택한 분석 범위에 대해 아래 공식으로 계산
measures:
  # 총매출: 할인 전 판매금액 합계
  - name: gross_sales
    expr: SUM(gross_sales)
  # 할인액: 적용된 할인 금액 합계
  - name: discount_amount
    expr: SUM(discount_amount)
  # 순매출: 할인 후 판매금액 합계
  - name: net_sales
    expr: SUM(net_sales)
  # 주문수: 고유 주문 ID의 개수
  - name: order_count
    expr: COUNT(DISTINCT order_id)
  # 판매수량: 판매한 상품 수량 합계
  - name: item_quantity
    expr: SUM(quantity)
  # 객단가: 순매출 합계 ÷ 고유 주문수
  - name: avg_order_value
    expr: SUM(net_sales) / COUNT(DISTINCT order_id)
$$;

-- COMMAND ----------

-- 방금 정의한 지표를 조회합니다. MEASURE는 Metric View의 계산 정의를 사용합니다.
-- 여기서는 매장 등으로 나누지 않고 전체 기간의 값을 확인합니다.
-- 예상값: 순매출 1,734,580원 / 주문수 266건 / 객단가 약 6,520.98원
SELECT
  MEASURE(net_sales) AS net_sales,
  MEASURE(order_count) AS order_count,
  MEASURE(avg_order_value) AS avg_order_value
FROM cafe_training.cafe_hands_on.cafe_sales_metrics;
