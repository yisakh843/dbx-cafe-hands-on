-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 00. 카페 핸즈온 환경 준비
-- MAGIC
-- MAGIC 개인 Workspace에서 실행하는 시작 노트북입니다.
-- MAGIC 기본 Catalog는 `cafe_training`입니다. Catalog 생성 권한이 없으면 Catalog 관리자에게 생성을 요청합니다.
-- MAGIC
-- MAGIC **실행 환경:** SQL Warehouse를 연결하고 셀을 위에서부터 실행합니다.
-- MAGIC **결과물:** Catalog 1개, Schema 2개, CSV 업로드용 Volume 1개를 준비합니다.
-- MAGIC 이 노트북은 CSV를 자동 업로드하지 않습니다. 생성 후 아래 경로로 파일을 올립니다.

-- COMMAND ----------

-- Catalog → Schema → Table/View 또는 Volume 순서로 데이터를 관리합니다.
-- IF NOT EXISTS: 같은 이름이 이미 있으면 새로 만들지 않고 기존 객체를 유지합니다.
CREATE CATALOG IF NOT EXISTS cafe_training;

-- Landing Schema: CSV 파일을 보관할 Volume의 위치
CREATE SCHEMA IF NOT EXISTS cafe_training.cafe_landing
COMMENT '카페 핸즈온 원천 파일용 스키마';

-- Analytics Schema: Pipeline이 만든 테이블과 Metric View의 위치
CREATE SCHEMA IF NOT EXISTS cafe_training.cafe_hands_on
COMMENT '카페 핸즈온 Bronze, Silver, Gold, Metric View용 스키마';

-- Volume: 테이블 행이 아니라 CSV 같은 파일을 저장하는 공간
CREATE VOLUME IF NOT EXISTS cafe_training.cafe_landing.raw
COMMENT '카페 핸즈온 CSV 업로드 볼륨';

-- COMMAND ----------

-- 다음 로컬 폴더의 내용을 Catalog Explorer에서 Volume으로 업로드합니다.
-- sample_data/raw/stores.csv          -> /Volumes/cafe_training/cafe_landing/raw/stores.csv
-- sample_data/raw/products.csv        -> /Volumes/cafe_training/cafe_landing/raw/products.csv
-- sample_data/raw/orders/*.csv        -> /Volumes/cafe_training/cafe_landing/raw/orders/*.csv
-- sample_data/support/glossary.csv    -> /Volumes/cafe_training/cafe_landing/raw/support/glossary.csv

-- 경로 형식: /Volumes/<Catalog>/<Schema>/<Volume>
-- LIST는 파일·폴더 목록을 보여 줍니다. 업로드 전에는 목록이 비어 있을 수 있습니다.
LIST '/Volumes/cafe_training/cafe_landing/raw';

-- COMMAND ----------

-- 아래 결과는 사용할 경로 안내입니다. CSV 업로드 여부나 내용까지 검증하지는 않습니다.
SELECT
  '환경 준비 완료' AS status,
  '/Volumes/cafe_training/cafe_landing/raw' AS upload_path,
  'cafe_training.cafe_hands_on' AS target_schema;
