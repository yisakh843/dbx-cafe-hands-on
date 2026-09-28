# 2부 · 데이터 파이프라인

> 이 부에서 진행하는 절: **5~6절**

[← 1부 환경 준비](1_setup.md) · [목차](README.md) · [3부 Metric View와 Genie →](3_metric_genie.md)

<a id="step-5"></a>

## 5. Lakeflow Pipeline 생성

`01_cafe_medallion_pipeline.sql`은 Pipeline에서만 실행하는 소스입니다. 3절 setup 노트북처럼 SQL Warehouse에서 `Run all`하지 말고, 아래 순서대로 Pipeline에 연결합니다.

**이동:** `Jobs & Pipelines → ETL pipeline`

여기서는 **ETL pipeline**을 선택합니다. 옆의 **Job**은 6절에서 사용합니다.

<a href="../images/runbook/12-jobs-entry.jpg"><img src="../images/runbook/12-jobs-entry.jpg" alt="Jobs & Pipelines에서 ETL pipeline 선택" width="800">

</a>

<sub>*화면 13 · ETL pipeline 진입 메뉴*</sub>

`ETL pipeline`을 누르면 기본 Pipeline과 빈 소스 파일이 자동으로 만들어집니다. 상단 Pipeline 이름을 `cafe_medallion_pipeline`으로 바꾸고 Enter를 누른 뒤 **Settings**를 엽니다.

Settings에서 **Code assets**와 **Default location for data assets**를 확인합니다. 아래 화면 15\~16은 패널을 아래로 내리면 나오는 **Legacy pipeline settings**에서 촬영한 것입니다.

<a href="../images/runbook/13-pipeline-settings-entry.jpg"><img src="../images/runbook/13-pipeline-settings-entry.jpg" alt="Pipeline 설정 진입 화면" width="720">

</a>

<sub>*화면 14 · Pipeline 설정*</sub>

Pipeline 설정:


| 항목              | 값                                           |
| --------------- | ------------------------------------------- |
| Pipeline name   | `cafe_medallion_pipeline`                   |
| Source file     | `notebooks/01_cafe_medallion_pipeline.sql`  |
| Catalog         | `cafe_training`                             |
| Schema          | `cafe_hands_on`                             |
| Serverless      | On                                          |
| Product edition | Advanced                                    |
| Channel         | Current (Default Storage 사용 시 Preview로 고정됨) |
| Pipeline mode   | Triggered                                   |


Source가 폴더 단위로 표시되면 다음 폴더에서 `01_cafe_medallion_pipeline.sql`을 선택합니다.

```text
/Workspace/Users/<사용자 이메일>/dbx-cafe-hands-on/notebooks
```

자동으로 들어가 있던 `transformations/**` 경로는 지우고 **01\_cafe\_medallion\_pipeline** 하나만 선택합니다. `notebooks` 폴더 전체를 지정하면 setup·Metric View·검증 파일까지 함께 실행되니 꼭 파일 하나만 지정합니다.

<a href="../images/runbook/14-pipeline-source-annotated.png"><img src="../images/runbook/14-pipeline-source-annotated.png" alt="Git folder에서 Pipeline 전용 노트북 선택" width="720">

</a>

<sub>*화면 15 · Pipeline 소스 선택*</sub>

Source code의 **Path**, Destination의 **cafe\_training / cafe\_hands\_on**을 확인하고 **Save**합니다. Free Edition은 Default Storage를 사용하기 때문에 Channel이 **Preview**로 표시되는 것이 정상입니다. Product edition 선택란이 보이지 않으면 그대로 두셔도 됩니다.

<a href="../images/runbook/15-pipeline-settings-annotated.png"><img src="../images/runbook/15-pipeline-settings-annotated.png" alt="Pipeline의 소스 경로와 출력 위치 설정" width="720">

</a>

<sub>*화면 16 · 소스 경로와 출력 위치*</sub>

저장했으면 **Run pipeline**을 클릭합니다.

실행하면 다음 데이터셋이 만들어집니다.

- bronze\_stores, bronze\_products, bronze\_orders
- silver\_stores, silver\_products, silver\_orders\_clean
- gold\_sales

**완료 확인:** 상태가 **Completed**이고 7개 데이터셋이 모두 성공으로 표시됩니다. DAG가 초록색인 것만 보지 말고, 아래 Tables의 Output records에서 `bronze_orders` 300행, `gold_sales` 266행인지도 확인합니다.

<a href="../images/runbook/19-pipeline-completed.jpg"><img src="../images/runbook/19-pipeline-completed.jpg" alt="Pipeline 실행 성공과 Bronze·Silver·Gold DAG" width="720">

</a>

<sub>*화면 17 · Pipeline 실행 결과*</sub>

Catalog Explorer의 `cafe_training.cafe_hands_on`에서도 만들어진 테이블을 볼 수 있습니다.

---

<a id="step-6"></a>

## 6. Lakeflow Job 생성

**이동:** `Jobs & Pipelines → Job`

상단에 자동으로 붙은 Job 이름을 클릭해 `cafe_medallion_job`으로 바꾸고 Enter를 누릅니다. 이어서 **Add another task type → ETL Pipeline**으로 첫 Task를 추가합니다.

### 6-1. Pipeline 실행 Task


| 항목           | 값                         |
| ------------ | ------------------------- |
| Task name    | `run_medallion_pipeline`  |
| Task type    | Pipeline                  |
| Pipeline     | `cafe_medallion_pipeline` |
| Full refresh | Off                       |


**Task name**, **Pipeline**을 확인하고 **Trigger a full refresh**는 체크하지 않습니다. **Save task**를 누릅니다.

<a href="../images/runbook/16-job-pipeline-task-annotated.png"><img src="../images/runbook/16-job-pipeline-task-annotated.png" alt="Job의 Pipeline 실행 Task 설정" width="720">

</a>

<sub>*화면 18 · Pipeline 실행 Task*</sub>

### 6-2. Pipeline 검증 Task

**Add task → SQL file**을 선택하고 다음 값을 입력합니다. 저장한 뒤 다시 열면 **Type = SQL / SQL task = File**로 표시되는데, 같은 설정입니다.


| 항목            | 값                        |
| ------------- | ------------------------ |
| Task name     | `validate_pipeline`      |
| Task type     | SQL file                 |
| SQL Warehouse | 앞 단계에서 사용한 SQL Warehouse |


**SQL 파일:** `notebooks/04_pipeline_validate.sql`

Workspace Source인 경우:

```text
/Workspace/Users/<사용자 이메일>/dbx-cafe-hands-on/notebooks/04_pipeline_validate.sql
```

Git provider Source인 경우:


| 항목         | 값                                                    |
| ---------- | ---------------------------------------------------- |
| Repository | `https://github.com/yisakh843/dbx-cafe-hands-on.git` |
| Branch     | `main`                                               |
| Path       | `notebooks/04_pipeline_validate.sql`                 |


**Users → 본인 계정 → dbx-cafe-hands-on → notebooks → 04\_pipeline\_validate.sql**을 선택하고 **Confirm**합니다.

<a href="../images/runbook/17-job-sql-file-annotated.png"><img src="../images/runbook/17-job-sql-file-annotated.png" alt="Job 검증용 SQL 파일 선택" width="720">

</a>

<sub>*화면 19 · 검증 SQL 파일 선택*</sub>

**SQL warehouse**, **Depends on = run\_medallion\_pipeline**, **Run if dependencies = All succeeded**를 확인한 뒤 **Create task**를 누릅니다.

<a href="../images/runbook/18-job-validation-task-annotated.png"><img src="../images/runbook/18-job-validation-task-annotated.png" alt="검증 Task의 Warehouse와 의존성" width="720">

</a>

<sub>*화면 20 · 검증 Task 설정*</sub>

완성된 Job DAG는 다음과 같습니다.

```text
run_medallion_pipeline
          ↓
   validate_pipeline
```

### 6-3. Job 실행과 결과 확인

`Save`한 뒤 `Run now`를 클릭합니다. 두 Task가 모두 **Succeeded**가 되면 검증 Task를 열어 결과 표를 확인합니다. 행 순서는 달라도 괜찮습니다.


| 테이블                   | 실제  | 기대  | 결과   |
| --------------------- | ---: | ---: | ---- |
| bronze\_orders        | 300 | 300 | PASS |
| silver\_orders\_clean | 296 | 296 | PASS |
| gold\_sales           | 266 | 266 | PASS |


> **주의:** Job이 성공으로 끝나도 결과 표의 세 행이 모두 `PASS`인지 꼭 확인해야 합니다. 검증 SQL은 값이 달라도 `FAIL`로 표시만 할 뿐 오류를 내지 않기 때문에, Job 상태만으로는 알 수 없습니다.

<a href="../images/runbook/28-job-succeeded.jpg"><img src="../images/runbook/28-job-succeeded.jpg" alt="Pipeline 실행과 SQL 검증 task가 모두 성공한 Job" width="720">

</a>

<sub>*화면 21 · Job 실행 결과*</sub>

촬영 환경에서는 Pipeline Task 41초, 검증 Task 23초가 걸렸습니다. 소요 시간은 환경에 따라 달라집니다.

<a href="../images/runbook/29-validation-pass-annotated.png"><img src="../images/runbook/29-validation-pass-annotated.png" alt="검증 SQL의 Bronze·Silver·Gold 행 수가 모두 PASS인 결과" width="720">

</a>

<sub>*화면 22 · 행 수 검증 결과*</sub>

---

[← 1부 환경 준비](1_setup.md) · [목차](README.md) · [3부 Metric View와 Genie →](3_metric_genie.md)
