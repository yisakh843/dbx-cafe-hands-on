# Databricks notebook source
# MAGIC %md
# MAGIC # 05. 카페 용어집 AI Search 구성
# MAGIC
# MAGIC 제공된 `glossary.csv`를 Delta 테이블로 만들고 Triggered Delta Sync Index를 생성합니다.
# MAGIC **사전 준비:** Setup과 `support/glossary.csv` 업로드를 마치고 Python Compute를 연결합니다.
# MAGIC **결과물:** 용어집 원본 테이블, 검색을 제공하는 Endpoint, 검색용 Index를 만듭니다.
# MAGIC **실행 순서:** 셀을 하나씩 실행합니다. Endpoint 준비와 Index 초기 동기화가 끝났는지 확인한 뒤 다음 단계로 갑니다.
# MAGIC 재실행 시 원본 테이블은 CSV로 교체되고, 같은 이름의 Endpoint·Index는 재사용을 시도합니다.
# MAGIC
# MAGIC `%pip`로 노트북용 SDK를 설치하고 Python을 재시작합니다. 재시작 후 다음 셀부터 실행합니다.

# COMMAND ----------

# MAGIC %pip install -q --upgrade databricks-ai-search
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

# Databricks widgets로 환경별 Catalog·Schema·Endpoint·모델을 매개변수화합니다.
# 공유 환경에서는 강사가 지정한 이름을 사용하며, 모델은 Workspace에서 사용 가능해야 합니다.
dbutils.widgets.text("catalog", "cafe_training", "Catalog")
dbutils.widgets.text("schema", "cafe_hands_on", "Schema")
dbutils.widgets.text("endpoint_name", "cafe-ai-search-endpoint", "AI Search endpoint")
dbutils.widgets.text("embedding_model", "databricks-qwen3-embedding-0-6b", "Embedding model")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
endpoint_name = dbutils.widgets.get("endpoint_name")
embedding_model = dbutils.widgets.get("embedding_model")

# source_table은 검색 원본, index_name은 원본을 동기화한 검색용 객체입니다.
# 위 schema 위젯은 출력 위치입니다. CSV 입력 경로의 cafe_landing은 고정되어 있습니다.
source_table = f"{catalog}.{schema}.cafe_glossary"
index_name = f"{catalog}.{schema}.cafe_glossary_index"
glossary_path = f"/Volumes/{catalog}/cafe_landing/raw/support/glossary.csv"

print({"source_table": source_table, "index_name": index_name, "glossary_path": glossary_path})

# COMMAND ----------

glossary_df = (
    spark.read.option("header", True)
    .option("encoding", "UTF-8")
    .csv(glossary_path)
)
glossary_df.createOrReplaceTempView("cafe_glossary_upload")

# Delta Change Data Feed: 원본의 행 변경을 추적해 Delta Sync Index의 증분 동기화에 사용합니다.
# 이 셀을 재실행하면 원본 용어집이 CSV 내용으로 교체됩니다.
spark.sql(
    f"""
    CREATE OR REPLACE TABLE {source_table}
    TBLPROPERTIES (delta.enableChangeDataFeed = true)
    COMMENT '카페 약어·동의어·다의어와 지표 해석 규칙'
    AS SELECT * FROM cafe_glossary_upload
    """
)

# 제공 샘플은 19행입니다. term_id가 비어 있지 않고 중복되지 않는지도 확인합니다.
display(spark.table(source_table))

# COMMAND ----------

from databricks.ai_search.client import AISearchClient

# AI Search Endpoint는 Index를 호스팅하고 검색 요청을 처리하는 리소스입니다.
client = AISearchClient()

# Endpoint 조회 오류에는 권한·연결 문제도 포함될 수 있습니다.
try:
    client.get_endpoint(name=endpoint_name)
    print(f"기존 endpoint 사용: {endpoint_name}")
except Exception:
    client.create_endpoint(name=endpoint_name, endpoint_type="STANDARD")
    print(f"endpoint 생성 요청: {endpoint_name}")

# 생성 요청은 준비 완료가 아닙니다. Endpoint가 ONLINE이 될 때까지 UI에서 상태를 확인합니다.

# COMMAND ----------

# 기존 Index를 재사용하면 아래 생성 옵션을 다시 적용하지 않습니다.
# 원본 테이블·Endpoint·Embedding 모델이 이번 실습 설정과 일치하는지 확인합니다.
try:
    index = client.get_index(index_name=index_name)
    print(f"기존 index 사용: {index_name}")
except Exception:
    index = client.create_delta_sync_index(
        endpoint_name=endpoint_name,
        source_table_name=source_table,
        index_name=index_name,
        # TRIGGERED: 필요할 때 sync()로 동기화를 요청하는 방식
        pipeline_type="TRIGGERED",
        # 각 용어를 구분할 고유 ID. 원본 테이블에 SQL PRIMARY KEY 제약을 만드는 옵션은 아닙니다.
        primary_key="term_id",
        # 용어·별칭·정의·규칙을 모은 텍스트를 Embedding 모델로 벡터화합니다.
        embedding_source_column="search_text",
        # 위에서 선택한 모델 Endpoint 이름. 검색용 Endpoint와는 역할이 다릅니다.
        embedding_model_endpoint_name=embedding_model,
        # 검색 결과에서 함께 읽을 메타데이터 컬럼을 Index에 복사합니다.
        columns_to_sync=[
            "term",
            "aliases",
            "definition",
            "metric_or_field",
            "resolution_rule",
            "example_question",
            "search_text",
        ],
    )
    print(f"index 생성 요청: {index_name}")

# COMMAND ----------

# 처음 생성한 Index의 초기 동기화가 끝났는지 확인한 뒤 실행합니다.
# sync()는 시작 요청입니다. 완료 상태와 Indexed rows=19를 확인한 후 검색 셀로 이동합니다.
index = client.get_index(index_name=index_name)
index.sync()
print("Triggered sync를 시작했습니다. Catalog Explorer에서 ONLINE 상태를 확인하세요.")

# COMMAND ----------

index = client.get_index(index_name=index_name)
# 이 검색은 매출을 계산하지 않습니다. 질문 속 용어의 뜻과 처리 규칙을 찾습니다.
results = index.similarity_search(
    query_text="아메 매출과 피크타임을 알려줘",
    # Index에 동기화된 컬럼 중 응답에 포함할 컬럼
    columns=["term_id", "term", "definition", "resolution_rule"],
    num_results=3,
    # HYBRID는 단어 일치와 벡터 의미 유사도를 함께 활용합니다.
    query_type="HYBRID",
)
# definition으로 뜻을 읽고 resolution_rule로 바로 조회할지 사용자에게 되물을지 판단합니다.
display(results)
