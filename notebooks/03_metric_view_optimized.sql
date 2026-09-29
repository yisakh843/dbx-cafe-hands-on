-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03. Metric View 의미·성능 최적화
-- MAGIC
-- MAGIC 기준선에 설명, 표시명, 동의어, 숫자 포맷과 일 단위 Materialization을 추가합니다.
-- MAGIC 작은 샘플이라 절대 지연시간 차이는 작지만, 동일 벤치마크의 SQL 정확도와 일관성을 비교할 수 있습니다.
-- MAGIC
-- MAGIC ## 코드를 읽는 예: “지점별 매출을 알려줘”
-- MAGIC
-- MAGIC - `fields`의 `store_name`은 데이터를 매장별로 나누는 기준입니다. `synonyms`의 “지점”은 이 필드를 찾는 데 도움을 줍니다.
-- MAGIC - `measures`의 `net_sales`는 계산할 지표입니다. “매출”이라는 동의어와 `comment`의 업무 설명을 보고 이 지표를 선택하도록 돕습니다.
-- MAGIC - 실제 금액은 `expr: SUM(net_sales)`로 계산하고, `display_name`과 `format`은 결과를 읽기 쉽게 표시하는 데 쓰입니다.
-- MAGIC
-- MAGIC **`# 설명`과 `comment:`의 차이:** `#`는 이 코드를 읽는 사람을 위한 YAML 주석입니다. YAML 1.1 정의를 저장할 때 제거되므로, Genie 등에 전달할 업무 설명은 `comment:`에 적습니다.
-- MAGIC 동의어는 필드·지표를 찾는 단서입니다. 예를 들어 “상품명”의 동의어 “메뉴”를 등록해도, 상품 값 “아메”를 “아메리카노”로 치환하는 규칙이 생기지는 않습니다.
-- MAGIC
-- MAGIC 참고: [공식 YAML 문법](https://docs.databricks.com/aws/en/uc-semantics/metric-views/yaml-reference), [의미 정보 설정](https://docs.databricks.com/aws/en/uc-semantics/agent-metadata), [Materialization](https://docs.databricks.com/aws/en/uc-semantics/metric-views/materialization)

-- COMMAND ----------

CREATE OR REPLACE VIEW cafe_training.cafe_hands_on.cafe_sales_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
# version: Metric View YAML 명세 버전. 표시명·동의어·포맷에 필요한 1.1을 사용합니다.
version: 1.1
# 최상위 comment: 이 Metric View 전체가 어떤 데이터를 분석하는지 설명합니다.
comment: '완료된 카페 주문의 매장·상품·시간대별 매출 분석용 표준 Metric View'
# source: 실제로 읽을 원천 테이블 또는 뷰. 여기서는 완료 주문을 담은 Gold 데이터입니다.
source: cafe_training.cafe_hands_on.gold_sales

# fields: 나눠 보거나 필터링할 분석 기준(차원). 예: 매장별, 날짜별, 상품별
fields:
  # name: SQL에서 참조할 필드 이름
  - name: order_date
    # expr: 원천 데이터에서 값을 가져오거나 가공하는 SQL 식. 여기서는 같은 이름의 컬럼
    expr: order_date
    # display_name: 지원하는 시각화 도구에서 보여 줄 이름. name 자체를 바꾸지는 않습니다.
    display_name: '주문일'
    # comment: 이 필드의 뜻·범위·업무 규칙을 담는 메타데이터
    comment: '주문이 완료된 달력 날짜. 데이터 기간은 2026-07-01부터 2026-07-14까지다.'
    # synonyms: 사용자가 같은 필드를 부르는 다른 이름. Genie 등의 필드 탐색을 돕습니다.
    synonyms: ['판매일', '일자', '날짜']
  - name: day_name
    expr: day_name
    display_name: '요일'
    comment: '월, 화, 수, 목, 금, 토, 일 중 하나인 한글 요일'
    synonyms: ['주문 요일', '판매 요일']
  - name: day_type
    expr: day_type
    display_name: '주중 구분'
    comment: '토요일과 일요일은 주말, 나머지는 평일'
    synonyms: ['평일 주말', '주말 여부']
  - name: daypart
    expr: daypart
    display_name: '시간대'
    comment: '모닝 06~10시, 점심 11~13시, 오후 14~17시, 저녁 18~21시, 야간 22~05시'
    synonyms: ['피크타임', '판매 시간대', '주문 시간대']
  - name: store_name
    expr: store_name
    display_name: '매장명'
    comment: '강남점, 판교점, 해운대점 중 하나'
    synonyms: ['지점', '매장', '점포']
  - name: region
    expr: region
    display_name: '지역'
    comment: '매장이 위치한 광역 지역'
    synonyms: ['권역', '매장 지역']
  - name: product_name
    expr: product_name
    display_name: '상품명'
    comment: '판매한 카페 메뉴의 정식 상품명'
    synonyms: ['메뉴', '제품', '상품']
  - name: category
    expr: category
    display_name: '상품 카테고리'
    comment: '커피, 음료, 푸드, 디저트 중 하나'
    synonyms: ['메뉴 구분', '상품군', '제품군']

# measures: 합계·개수·비율 등 집계 지표. 조회할 때 MEASURE(지표 이름)으로 사용합니다.
# fields로 정한 그룹과 필터에 따라 expr의 집계 범위가 달라집니다.
measures:
  - name: gross_sales
    # expr: 지표의 실제 계산식. 표시명이나 동의어를 추가해도 이 식은 그대로입니다.
    expr: SUM(gross_sales)
    display_name: '총매출'
    comment: '할인 적용 전 완료 주문의 판매금액 합계'
    synonyms: ['할인 전 매출', '총 판매액']
    # format: 지원하는 도구에서 값을 표시하는 형식. 저장된 값이나 계산식을 바꾸지 않습니다.
    format:
      # currency: 통화 형식 / KRW: 원화. 환율 변환을 수행하는 설정은 아닙니다.
      type: currency
      currency_code: KRW
      # exact + places: 0: 소수점 이하를 0자리로 표시합니다.
      decimal_places: { type: exact, places: 0 }
  - name: discount_amount
    expr: SUM(discount_amount)
    display_name: '할인액'
    comment: '완료 주문에 적용된 할인 금액 합계'
    synonyms: ['할인 금액', '총 할인']
    format:
      type: currency
      currency_code: KRW
      decimal_places: { type: exact, places: 0 }
  - name: net_sales
    expr: SUM(net_sales)
    display_name: '순매출'
    # "매출"의 기본 의미를 명시하여 총매출·순매출 중 어느 지표를 쓸지 판단하도록 돕습니다.
    comment: '할인 적용 후 완료 주문의 판매금액 합계. 사용자가 매출이라고만 하면 이 지표를 기본으로 사용한다.'
    synonyms: ['매출', '실매출', '결제매출', '판매액']
    format:
      type: currency
      currency_code: KRW
      decimal_places: { type: exact, places: 0 }
  - name: order_count
    expr: COUNT(DISTINCT order_id)
    display_name: '주문수'
    comment: '완료된 고유 주문 ID의 개수'
    synonyms: ['주문 건수', '결제 건수', '건수']
    format:
      # number: 통화가 아닌 일반 숫자로 표시합니다. 여기서는 주문 건수입니다.
      type: number
      decimal_places: { type: exact, places: 0 }
  - name: item_quantity
    expr: SUM(quantity)
    display_name: '판매수량'
    comment: '완료 주문에서 판매된 상품 수량 합계'
    synonyms: ['판매량', '상품 개수', '잔수']
    format:
      type: number
      decimal_places: { type: exact, places: 0 }
  - name: avg_order_value
    # 조회 범위의 순매출 합계 ÷ 고유 주문수. 매장별 객단가를 단순 평균하는 계산이 아닙니다.
    expr: SUM(net_sales) / COUNT(DISTINCT order_id)
    display_name: '객단가'
    comment: '순매출을 완료 주문수로 나눈 평균 주문금액'
    synonyms: ['주문단가', '평균 결제금액', 'AOV']
    format:
      type: currency
      currency_code: KRW
      decimal_places: { type: exact, places: 0 }

# materialization: 자주 쓰는 집계 결과를 미리 계산·저장해 조회를 빠르게 하는 설정
# 계산 의미를 설명하는 위 메타데이터와 별도로, 갱신용 컴퓨팅과 저장 공간을 사용합니다.
materialization:
  # schedule: 미리 계산한 결과를 갱신하는 주기. 여기서는 하루마다 갱신하도록 설정합니다.
  schedule: every 1 day
  # relaxed: 갱신 이후 원천이 바뀌었어도 저장된 집계가 조회에 사용될 수 있습니다.
  # 따라서 최신 원천 데이터와 조회 결과 사이에 시차가 생길 수 있습니다.
  mode: relaxed
  # materialized_views: 미리 만들어 유지할 집계 정의 목록
  materialized_views:
    - name: daily_store_category
      # aggregated: 아래 dimensions 조합별로 measures를 미리 집계합니다.
      type: aggregated
      # dimensions: 위 fields 중 집계에 사용할 기준. 날짜 × 매장 × 카테고리 조합
      dimensions:
        - order_date
        - store_name
        - category
      # 이 measures 목록은 위에서 정의한 지표 이름을 참조합니다.
      measures:
        - gross_sales
        - discount_amount
        - net_sales
        - order_count
        - item_quantity
      # cluster_by.auto: 저장 데이터의 클러스터링 키 선택을 Databricks에 맡깁니다.
      cluster_by:
        auto: true
$$;

-- COMMAND ----------

-- 저장된 Metric View의 컬럼·메타데이터 등 상세 정보를 확인합니다.
DESCRIBE EXTENDED cafe_training.cafe_hands_on.cafe_sales_metrics;
