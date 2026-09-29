# Databricks notebook source
# MAGIC %md
# MAGIC # 06. Supervisor Agent MLflow 모니터링·평가
# MAGIC
# MAGIC 먼저 Databricks App에서 `agent_evaluation.csv` 질문을 실행해 Trace를 생성합니다.
# MAGIC 이 노트북은 최근 Trace를 조회하고 개발 평가와 선택적 프로덕션 모니터링을 설정합니다.

# COMMAND ----------

# MAGIC %pip install -q --upgrade "mlflow[databricks]>=3.4.0"
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

import mlflow

dbutils.widgets.text("experiment_path", "/Shared/cafe-supervisor-agent", "MLflow experiment")
experiment_path = dbutils.widgets.get("experiment_path")
experiment = mlflow.get_experiment_by_name(experiment_path)
if experiment is None:
    raise ValueError(
        "Experiment를 찾지 못했습니다. App Export에서 선택한 전체 경로를 확인하세요. "
        "빈 Experiment를 새로 만들지 않고 중단합니다."
    )
mlflow.set_experiment(experiment_id=experiment.experiment_id)

print(f"MLflow experiment: {experiment.name} (ID: {experiment.experiment_id})")

# COMMAND ----------

traces = mlflow.search_traces(
    experiment_ids=[experiment.experiment_id], max_results=30
)
print(f"조회한 Trace: {len(traces)}개")
display(traces)

# Trace가 없다면 Databricks App에서 평가 질문을 실행한 후 이 셀부터 다시 실행하세요.
# 최근 30개에는 다른 대화도 포함될 수 있습니다. 입력 질문과 실행 시각을 확인하고,
# 이번 실습만 평가하려면 traces = traces[traces["trace_id"].isin([...])]로 좁힙니다.
# agent_evaluation.csv의 기대 경로는 자동으로 읽거나 채점하지 않습니다.

# COMMAND ----------

from mlflow.genai.scorers import (
    RelevanceToQuery,
    Safety,
    ToolCallCorrectness,
)

if len(traces) > 0:
    evaluation = mlflow.genai.evaluate(
        data=traces,
        scorers=[
            RelevanceToQuery(),
            Safety(),
            ToolCallCorrectness(),
        ],
    )
    print("Evaluation metrics:")
    print(evaluation.metrics)
    display(evaluation.result_df)
else:
    print("평가할 Trace가 없습니다. App에서 질문을 먼저 실행하세요.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 선택 실습: 프로덕션 샘플링 모니터링
# MAGIC
# MAGIC 이 기능은 워크스페이스에서 Production Monitoring Preview가 활성화된 경우에만 실행합니다.
# MAGIC 아래 코드를 실행해 Trace와 평가 결과를 확인합니다.

# COMMAND ----------

# from mlflow.genai.scorers import Safety, ScorerSamplingConfig
#
# safety_monitor = Safety().register(name="cafe_safety")
# safety_monitor = safety_monitor.start(
#     sampling_config=ScorerSamplingConfig(sample_rate=0.5)
# )
# print(safety_monitor)
