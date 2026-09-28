# Databricks Cafe Hands-on 실행 가이드

이 가이드를 따라 본인의 Databricks Free Edition Workspace에 실습 저장소를 연결하고, 카페 매출 데이터로 메달리온 Pipeline, Lakeflow Job, Metric View, Genie Agent를 차례로 만들어 봅니다.

## 처음 실습하는 분께

이 페이지에서 이름 규칙과 사전 조건을 먼저 확인한 뒤, 아래 파트를 순서대로 진행합니다. 단계마다 예상 결과가 나왔는지 확인한 뒤 다음으로 넘어갑니다. 샘플 데이터의 기간은 **2026-07-01\~2026-07-14**입니다.


| 파트 | 절 | 하는 일 | 완료하면 보이는 결과 |
|---|---|---|---|
| [1. 환경 준비](1_setup.md) | 2~4절 | 실습 코드와 CSV 준비 | 개인 Git folder와 CSV 6개가 들어 있는 Volume |
| [2. 데이터 파이프라인](2_pipeline.md) | 5~6절 | 데이터 정리 및 실행 자동화 | Bronze 300행 → Silver 296행 → Gold 266행 |
| [3. Metric View와 Genie](3_metric_genie.md) | 7~12절 | 매출 계산 기준 정의, 자연어 분석과 답변 평가 | 순매출 1,734,580원, Genie 답변, Benchmark 결과 |
| [4. 심화 실습](4_advanced.md) | 13~16절 | 용어 검색과 Agent 앱 연결 | AI Search, Supervisor, App, MLflow Trace |

전체를 모두 진행하면 약 5시간 15분이 걸립니다. 3시간 기초 과정은 12절까지 진행하고, 13\~16절은 심화 실습으로 따로 다룹니다. 강사가 안내하는 범위까지 진행합니다.

### 빠른 이동


| 구간                  | 바로 가기                                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 환경 준비               | [네이밍 규칙](#step-0) · [사전 조건](#step-1) · [저장소 받기](1_setup.md#step-2) · [Catalog 준비](1_setup.md#step-3) · [CSV 업로드](1_setup.md#step-4)               |
| 데이터 파이프라인           | [Pipeline](2_pipeline.md#step-5) · [Job과 검증](2_pipeline.md#step-6)                                                                           |
| Metric View · Genie | [기준선](3_metric_genie.md#step-7) · [최적화](3_metric_genie.md#step-8) · [Genie 생성](3_metric_genie.md#step-9) · [예제](3_metric_genie.md#step-10) · [Benchmark](3_metric_genie.md#step-11) · [품질 개선](3_metric_genie.md#step-12) |
| 심화 실습               | [AI Search](4_advanced.md#step-13) · [Apps](4_advanced.md#step-14) · [MLflow](4_advanced.md#step-15) · [통합 검증](4_advanced.md#step-16)                                  |
| 마무리                 | [강사용 배포](5_instructor.md#step-17) · [기초 확인표](3_metric_genie.md#step-18) · [심화 확인표](4_advanced.md#step-18-advanced)                                                                            |


### 화면과 경로 읽는 법

아래는 Databricks Free Edition의 홈 화면입니다(2026-09-21 기준).

실습에서는 왼쪽 메뉴의 Workspace, Catalog, Jobs &amp; Pipelines, Genie Agents, SQL Warehouses, Playground를 주로 사용합니다.

<a href="../images/runbook/00-workspace-home.jpg"><img src="../images/runbook/00-workspace-home.jpg" alt="Databricks 홈과 실습에서 사용할 왼쪽 메뉴" width="600">

</a>

화면 1. 실습에서 사용할 홈 화면

> **화면 안내:** 그림은 Databricks Free Edition에서 직접 촬영한 화면입니다. 캡처에 보이는 계정 이메일과 리소스 ID는 촬영할 때의 값이니, 실습은 본인 계정에서 진행하시면 됩니다. 버튼 이름과 위치는 Workspace 버전에 따라 조금 다를 수 있습니다. 그림을 클릭하면 원래 크기로 볼 수 있습니다. 

- **Workspace**는 코드·노트북을 여는 곳입니다. **Catalog Explorer**는 테이블·Metric View·Volume을 확인하는 곳입니다.
- **Catalog → Schema → Table/Volume** 순으로 데이터가 정리됩니다. `cafe_training.cafe_hands_on.gold_sales`는 Catalog, Schema, Table 이름을 점으로 연결한 것입니다.
- `/Workspace/...`는 실습 코드 경로이고, `/Volumes/...`는 업로드한 데이터 파일 경로입니다. 두 경로를 혼동하지 않도록 주의합니다.
- `<사용자 이메일>`은 본인의 Databricks 로그인 이메일로 바꿔 입력합니다. 꺾쇠괄호(`< >`)는 빼고 입력합니다.
- **SQL Warehouse**는 SQL을 실행하는 컴퓨팅 자원입니다. Python 노트북에는 Python 실행이 가능한 Compute를 연결합니다.
- **Pipeline**은 Bronze·Silver·Gold 데이터를 만드는 처리 흐름이고, **Job**은 Pipeline 실행과 검증 작업의 순서를 관리합니다.

### 실행할 파일 구분


| 파일                                                                            | 실행 위치와 방법                                     |
| ----------------------------------------------------------------------------- | --------------------------------------------- |
| `00_setup.sql`, `02_metric_view_baseline.sql`, `03_metric_view_optimized.sql` | Workspace 노트북에서 SQL Warehouse를 선택하고 `Run all` |
| `01_cafe_medallion_pipeline.sql`                                              | 5절에서 Pipeline 소스로 등록하고 Pipeline 실행            |
| `04_pipeline_validate.sql`                                                    | 6절에서 Job의 SQL File task로 등록                   |
| `05_create_ai_search.py`, `06_mlflow_monitoring.py`                           | Python Compute를 연결하고 안내된 셀 순서대로 실행            |


> **오류가 나면:** 어떤 파일·셀에서 어떤 오류 메시지가 나왔는지, 어떤 Compute를 선택했는지 먼저 확인합니다. 앞 단계가 실패한 상태에서는 다음 단계로 넘어가지 말고 강사에게 화면을 보여 주시기 바랍니다.

<a id="step-0"></a>

## 0. 네이밍 규칙


| 대상                | 이름 또는 값                                              |
| ----------------- | ---------------------------------------------------- |
| GitHub repository | `https://github.com/yisakh843/dbx-cafe-hands-on.git` |
| Git branch        | `main`                                               |
| Git folder        | `dbx-cafe-hands-on`                                  |
| Catalog           | `cafe_training`                                      |
| Landing Schema    | `cafe_landing`                                       |
| Analytics Schema  | `cafe_hands_on`                                      |
| Volume            | `cafe_training.cafe_landing.raw`                     |
| Pipeline          | `cafe_medallion_pipeline`                            |
| Job               | `cafe_medallion_job`                                 |
| Pipeline task     | `run_medallion_pipeline`                             |
| Validation task   | `validate_pipeline`                                  |
| Metric View       | `cafe_training.cafe_hands_on.cafe_sales_metrics`     |
| Genie Agent       | `Cafe Sales Genie Agent`                             |


<a id="step-1"></a>

## 1. 사전 조건

교육 전에 **본인 계정으로 Databricks Free Edition에 가입하고 Workspace에 로그인**해 둡니다. 실습 객체는 각자의 Workspace에 만들기 때문에, 모두 0절의 이름(`cafe_training` 등)을 똑같이 사용하면 됩니다.

본인 Workspace에서 다음 기능과 권한을 사용할 수 있어야 합니다.

- Unity Catalog 사용
- `cafe_training`에 대한 `USE CATALOG`
- Schema 생성 권한
- Volume 생성·업로드 권한
- SQL Warehouse 사용 권한
- Serverless Lakeflow Pipeline 사용 권한
- Gold 테이블 `SELECT`
- `cafe_hands_on` Schema `CREATE TABLE`
- Genie Agent 생성·편집 권한

Catalog는 3절의 setup 노트북에서 만듭니다. 만들거나 실행하다가 실패하면 본인의 Free Edition Workspace에 로그인되어 있는지 확인하고, 오류 메시지를 강사에게 보여 주시기 바랍니다. 13\~16절 심화 실습은 강사가 Free Edition에서 필요한 기능과 모델을 쓸 수 있는지 미리 확인한 뒤 진행합니다.

---

준비가 끝났으면 [1. 환경 준비 →](1_setup.md)로 넘어갑니다.
