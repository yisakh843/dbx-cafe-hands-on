# 00. 시작하기

참가자가 각자 만든 Databricks Free Edition 계정의 Workspace에서 실습 환경을 준비하는 안내서입니다. 교육 전에 본인 계정으로 로그인까지 완료합니다. 각자의 환경에서 실습하므로 모두 `cafe_training` 등 동일한 이름을 사용합니다.

## 1. 권한 확인

- Unity Catalog 사용
- `cafe_training` Catalog에 대한 `USE CATALOG`
- Schema 생성 권한
- Volume 생성·업로드 권한
- SQL Warehouse 사용 권한
- Serverless Lakeflow Pipeline 사용 권한

Catalog는 아래 setup 노트북에서 생성합니다. 생성 또는 실행이 실패하면 본인의 Free Edition Workspace에 로그인했는지 확인하고, 오류 메시지를 강사에게 보여 주세요.

## 2. Schema와 Volume 생성

Git folder에서 다음 노트북을 엽니다.

[`notebooks/00_setup.sql`](../notebooks/00_setup.sql)

노트북은 다음 객체를 생성합니다.

```text
cafe_training.cafe_landing
cafe_training.cafe_hands_on
cafe_training.cafe_landing.raw
```

## 3. CSV 업로드

다음 Volume 경로에 원천 CSV를 업로드합니다.

```text
/Volumes/cafe_training/cafe_landing/raw
```

파일 구조:

```text
raw/
├── stores.csv
├── products.csv
├── orders/
│   ├── orders_batch_001.csv
│   ├── orders_batch_002.csv
│   └── orders_batch_003.csv
└── support/
    └── glossary.csv
```

## 4. 완료 확인

- `cafe_training.cafe_landing` Schema 확인
- `cafe_training.cafe_hands_on` Schema 확인
- `raw` Volume 확인
- 매장·상품 CSV 확인
- 주문 배치 3개 확인
- `glossary.csv` 확인

완료 후 다음 단계로 이동합니다.
