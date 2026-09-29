# Databricks notebook source
# MAGIC %md
# MAGIC # 06. Supervisor Agent MLflow 모니터링·평가
# MAGIC
# MAGIC 먼저 Databricks App에서 `agent_evaluation.csv` 질문을 실행해 Trace를 생성합니다.
# MAGIC 이 노트북은 최근 Trace를 조회하고 개발 평가와 선택적 프로덕션 모니터링을 설정합니다.
# MAGIC **사전 준비:** App의 Trace 저장을 확인하고, 같은 Experiment의 전체 경로를 준비합니다. Python Compute에서 실행합니다.
# MAGIC **결과물:** Trace 목록, 질문별 평가 결과, 전체 평가 지표를 확인합니다. 이 노트북은 App에 질문을 자동 전송하지 않습니다.
# MAGIC Trace는 질문 한 번의 실행 기록이고, Span은 그 안의 모델·도구 호출 같은 개별 작업입니다.
# MAGIC
# MAGIC 첫 코드 셀은 Databricks 연동 기능을 포함한 MLflow를 설치합니다. 재시작 후 다음 셀부터 실행합니다.

# COMMAND ----------

# MAGIC %pip install -q --upgrade "mlflow[databricks]>=3.4.0"
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

import mlflow

# 기본 경로는 예시입니다. App Export에서 선택한 Experiment 경로로 바꿉니다.
dbutils.widgets.text("experiment_path", "/Shared/cafe-supervisor-agent", "MLflow experiment")
experiment_path = dbutils.widgets.get("experiment_path")
# 존재 여부를 먼저 확인하여 경로 오타로 빈 Experiment가 새로 생기는 것을 막습니다.
experiment = mlflow.get_experiment_by_name(experiment_path)
if experiment is None:
    raise ValueError(
        "Experiment를 찾지 못했습니다. App Export에서 선택한 전체 경로를 확인하세요. "
        "빈 Experiment를 새로 만들지 않고 중단합니다."
    )
# 이후 평가 결과를 기록할 Experiment를 지정합니다. App의 기록 위치 자체를 바꾸지는 않습니다.
mlflow.set_experiment(experiment_id=experiment.experiment_id)

print(f"MLflow experiment: {experiment.name} (ID: {experiment.experiment_id})")

# COMMAND ----------

# App과 동일한 Experiment ID로 Trace를 조회합니다.
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

# 저장된 Trace를 평가합니다. 지침을 수정했다면 App에서 새 Trace를 만든 후 다시 조회해야 합니다.
# 평가용 모델 호출이 발생할 수 있으며, 모델 접근 권한과 사용량을 확인합니다.
if len(traces) > 0:
    evaluation = mlflow.genai.evaluate(
        data=traces,
        scorers=[
            # 질문·응답 관련성. 매출 정답 검증은 별도입니다.
            RelevanceToQuery(),
            # 응답 안전성 평가
            Safety(),
            # 도구와 인자의 적절성을 평가하려면 TOOL 유형 Span이 기록되어 있어야 합니다.
            # 실습 CSV에 적힌 기대 호출 순서를 이 기본 설정이 자동 비교하지는 않습니다.
            ToolCallCorrectness(),
        ],
    )
    print("Evaluation metrics:")
    # metrics는 집계 결과, result_df는 개별 평가 결과입니다. 오류와 판정 이유도 함께 봅니다.
    print(evaluation.metrics)
    display(evaluation.result_df)
else:
    print("평가할 Trace가 없습니다. App에서 질문을 먼저 실행하세요.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 선택 실습: 프로덕션 샘플링 모니터링
# MAGIC
# MAGIC 이 기능은 워크스페이스에서 Production Monitoring Preview가 활성화된 경우에만 실행합니다.
# MAGIC 필요한 경우 아래 코드의 주석을 해제합니다. 등록·시작 후에는 새로 들어오는 Trace를 대상으로 평가가 계속됩니다.
# MAGIC `sample_rate=0.5`로 새 Trace의 50%를 샘플링해 평가합니다.
# MAGIC 실습을 마치고 자동 평가를 중단하려면 시작에 사용한 Scorer 객체의 `stop()`을 호출합니다.

# COMMAND ----------

# register는 현재 Experiment에 Scorer를 등록하고, start는 자동 평가를 시작합니다.
# from mlflow.genai.scorers import Safety, ScorerSamplingConfig
#
# safety_monitor = Safety().register(name="cafe_safety")
# safety_monitor = safety_monitor.start(
#     sampling_config=ScorerSamplingConfig(sample_rate=0.5)
# )
# print(safety_monitor)
