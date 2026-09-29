# 강사용: runbook 화면 캡처 확인표

캡처 기준일: 2026-09-21(기존 Databricks 화면), 2026-09-28(GitHub ZIP 다운로드 추가, 노트북 Catalog 패널 화면 교체). 대상: Databricks Free Edition의 실제 실습 화면과 실습 저장소의 GitHub 다운로드 메뉴. 교육은 참가자가 각자 만든 Free Edition 계정의 Workspace에서 진행합니다.

일반 메뉴 클릭과 화면 캡처가 동작함을 확인했습니다. 아래 표는 캡처 및 실행 검증 상태를 구분하여 관리합니다.

이미지는 `docs/images/runbook/`에 보관하고 `docs/runbook/` 각 파트의 해당 단계 바로 뒤에 상대 경로의 Markdown 이미지 링크(`[![설명](미리보기 경로)](원본 크기 이미지 경로)`)로 넣습니다. HTML을 표시하지 않는 뷰어에서도 읽을 수 있도록 HTML 태그를 사용하지 않습니다. 본문에는 `docs/images/runbook/thumbnails/`의 축소본을 사용합니다. 미리보기는 기존 표시 폭에 맞춰 기본 720px, 가로로 긴 캡처 800px, 홈 화면 600px로 만들며 종횡비를 유지합니다. 클릭하면 축소 전 이미지가 열립니다. 캡처를 교체할 때는 미리보기도 함께 갱신합니다. 캡처에는 실제 입력값과 버튼이 함께 보이게 하고, 그림 설명에서 클릭할 버튼과 확인할 값을 굵게 표시합니다. 본문의 실제 화면 31장 중 20장은 강조본(`*-annotated.png`)으로 연결했습니다. 교체 전후의 원본 캡처와 이전 강조본은 재작업 이력으로 보존합니다. 강조본은 imagegen 내장 이미지 편집으로 제작했습니다. 강조본이 있는 화면은 해당 강조본을 축소하고 클릭 링크도 강조본으로 연결합니다. 강조 전 원본은 재작업용으로 보존합니다. 일부 Owner·Workspace 경로에 교육 계정 이메일이 표시됩니다. 외부 공개 배포 시 공개 범위를 확인합니다. 실행 전 설정 화면과 실행 후 성공 화면을 구분합니다.

| 절 | 캡처할 화면 | 강조할 위치·확인할 값 | 상태 |
|---|---|---|---|
| 시작 | Databricks 홈 | 왼쪽 주요 메뉴 | 원본 캡처 완료 |
| 2 | Git folder 생성 입력창 | 저장소 URL, 폴더명, 생성 버튼 | 캡처 완료 · 실제 Clone 완료 |
| 2 | Clone된 폴더 | main 브랜치, docs·notebooks·sample_data | 캡처 완료 · main 확인 |
| 2-3 | GitHub 저장소의 Code 메뉴 | Code 버튼, Download ZIP | 캡처 완료 · 강조본 반영 |
| 3 | `00_setup.sql` 노트북 | Warehouse 선택, Run all, 성공 결과 | 캡처 완료 · 실행 완료 |
| 3 | 노트북 왼쪽 Catalog 트리 | cafe_training → 두 Schema → raw Volume | 노트북 화면으로 교체 완료 · 객체 생성 확인 |
| 4 | 노트북 왼쪽 Volume 메뉴의 디렉터리 생성·업로드 | orders 생성, 대상 경로와 파일 선택, Create·Upload | 노트북 화면으로 교체 완료 · 라이트 모드·빨간 테두리 적용 |
| 4 | 노트북 왼쪽 업로드 완료 트리 | 루트 CSV 2개, orders 3개, support 1개 | 교체 완료 · 실제 CSV 6개 업로드 및 트리 확인 |
| 5 | Pipeline 생성·소스 선택 | 이름, SQL 소스, Catalog, Schema, Serverless | 캡처 완료 · 저장 완료 |
| 5 | Pipeline 실행 결과 | Bronze → Silver → Gold 노드 성공 | 캡처 완료 · Completed, 7개 노드 확인 |
| 5 | Expectation 상세 결과(보강용) | `silver_orders_clean`의 `positive_quantity` 규칙과 해당 실행의 제외 2행 | UI 경로·실측 지표 확인 및 캡처 대기 · 본문은 SQL 규칙과 샘플 기대 결과로 설명 |
| 6 | Job의 Pipeline task | 이름, Pipeline 선택, Full refresh Off | 캡처 완료 · 저장 완료 |
| 6 | Job의 SQL File task | Warehouse, 파일, Depends on | 캡처 완료 · 의존 관계 저장 확인 |
| 6 | Job 실행 결과 | 두 task 성공 및 300/296/266 PASS | 캡처 완료 · 두 Task Succeeded 및 300/296/266 PASS 확인 |
| 7~8 | Metric View 정의와 조회 결과 | 순매출 1,734,580, 주문수 266, 설명·동의어 | 기준선 실제 값 확인 · 최적화 두 셀 succeeded 확인 · 최적화 후 지표 재조회 대기 |
| 9 | Genie 생성·연결 자산 | Metric View 하나만 선택 | 캡처 완료 · 생성·이름 저장 확인 |
| 9~10 | Context 지침과 Example Query 입력 | 질문·SQL 입력, 저장, 필수 예제 3개 (선택 3개) | 지침 저장·Examples 진입 확인 · 예제 등록 대기 |
| 10 | Genie 응답과 생성 SQL | 순매출 결과, Show code | 미완료 |
| 11 | Chat·Agent Benchmark 입력 | SQL Answer와 Evaluation note의 차이 | 미완료 |
| 11~12 | Evaluations·Monitor | Accuracy, 실패 문항, 생성 SQL | 미완료 |
| 13 | AI Search Endpoint·Index | ONLINE, 19행, TRIGGERED | 미완료 |
| 13 | Hybrid 검색 결과 | 아메·라떼·손님수의 용어 규칙 | 미완료 |
| 14-0 | Playground 모델·도구·지침 | Tools enabled, Genie, AI Search | 진입 화면 캡처 완료 · 모델 배포 안내 표시, 사용 모델 준비 필요 |
| 14 | Apps Export 입력창 | App 이름, MLflow Experiment | 미완료 |
| 14 | App Resources·실행 화면 | 리소스 연결, Running, 실제 응답 | 미완료 |
| 15~16 | MLflow Trace·Evaluation | Q1~Q4 도구 순서, latency, Scorer 결과 | 미완료 |

현재 **실제 화면 31장**을 본문에 반영했습니다. 2~7절은 실행 결과까지 확인했고, 8절은 최적화 SQL 두 셀 성공을 확인했습니다. 9절은 Agent 생성·이름·지침 저장을 확인했습니다. 10절은 예제 등록 진입 화면까지만 촬영했습니다. 11~16절은 Playground 사전 조건 화면을 제외한 실행·결과 캡처가 남아 있습니다.

배포 전에는 runbook의 ‘화면 검증 범위’를 실제 완료 상태에 맞게 갱신하고, 모든 이미지가 GitHub와 Databricks Git folder에서 열리는지 확인합니다.

## 강조 표시 검토 결과

2026-09-22에 본문의 화면 1~30을 모두 검토했습니다. 기존 6장에 10장을 추가해 **16장은 강조본**, **14장은 원본**을 사용합니다. 화면 번호는 runbook의 그림 설명 번호입니다. 이 검토 완료는 위 표에 남아 있는 실행·캡처 미완료 항목의 완료를 뜻하지 않습니다.

| 화면 번호 | 처리 | 판단 근거·표시 대상 |
|---|---|---|
| 2 | 추가 | 여러 생성 메뉴 중 Create → Git folder |
| 6 | 추가 | 개별 셀 실행과 혼동하지 않도록 상단 Run all |
| 9, 10, 11 | 추가 | 파일 종류마다 달라지는 업로드 목적지 raw / orders / support |
| 15 | 추가 | 폴더 전체 대신 01_cafe_medallion_pipeline 파일과 Select |
| 18 | 추가 | 연결할 Pipeline, 비워 둘 Full refresh 체크박스, Save task |
| 19 | 추가 | 04_pipeline_validate.sql 파일과 Confirm |
| 26 | 추가 | cafe_training.cafe_hands_on 소속 Metric View 하나와 Create |
| 28 | 추가 | Instructions 탭과 긴 입력란 아래의 Save |
| 3, 5, 16, 20, 22, 29 | 기존 강조 유지 | 저장소 URL·생성, Warehouse 연결, 출력 Catalog·Schema, Task 의존성, PASS 결과, Examples·Add |
| 1, 4, 7, 12, 14 | 원본 유지 | 전체 화면·폴더·객체 구조를 파악하는 화면. 캡처 밖의 메뉴에 표시를 만들지 않음 |
| 8, 13, 27 | 원본 유지 | 입력창·메뉴·설정값이 이미 분명하며 그림 설명으로 위치를 알 수 있음 |
| 17, 21, 24 | 원본 유지 | 성공 상태나 결과 표가 이미 눈에 띔 |
| 23, 25 | 원본 유지 | 화면 6에서 안내한 Run all 조작이 반복됨 |
| 30 | 원본 유지 | 모델 준비 전 상태를 설명하는 화면이며 특정 배포 선택을 유도하지 않음 |

추가 강조본은 `image_gen.imagegen`으로 제작했습니다. 공통 편집 지시는 원래 UI·텍스트·선택 상태를 유지하고 지정 대상에만 얇은 빨간 테두리를 추가하는 것입니다. 클릭 위치를 오해할 수 있는 체크표시는 추가하지 않았고, Full refresh 체크박스는 비워 둔 상태를 확인했습니다. 추가 강조본의 정확한 프롬프트와 출력 파일명은 [annotation-prompts.json](images/runbook/annotation-prompts.json)에 보관합니다.

2026-09-28에는 GitHub 저장소의 **Code → Download ZIP** 화면을 추가했습니다. 화면 4-1로 삽입해 기존 화면 번호는 유지했고, 두 클릭 위치에 빨간 테두리를 넣어 본문 표시 폭을 720px로 맞췄습니다. 이 추가 시점의 본문은 **강조본 17장, 원본 14장**이었습니다.

같은 날 화면 7~12의 6장을 `00_setup` 노트북의 왼쪽 Catalog 패널에서 직접 조작한 화면으로 교체했습니다. `raw`의 더보기 메뉴에서 디렉터리를 만들고, 각 대상의 **Upload to volume**으로 CSV를 실제 업로드했습니다. 여섯 장 모두 라이트 모드·빨간 사각 테두리·720px 표시 폭을 적용했으며, 최종 트리에서 파일 6개를 확인했습니다. 현재 본문은 **강조본 20장, 원본 11장**을 사용합니다.
