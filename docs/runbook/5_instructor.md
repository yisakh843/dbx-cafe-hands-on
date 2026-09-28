# 강사용 · GitHub 반영 및 배포

[← 4부 심화 실습](4_advanced.md) · [목차](README.md)

## 17. GitHub 반영 및 참가자 배포

이 절은 **강사·저장소 관리자용**입니다. 참가자는 건너뛰셔도 됩니다.

최종 검증이 끝난 문서와 이미지 파일을 함께 GitHub에 반영합니다. 로컬 저장소 `dbx-cafe-hands-on` 폴더에서 작업 브랜치로 커밋·push한 뒤, 저장소의 리뷰 절차에 따라 `main`에 병합합니다.

```powershell
git status                      # 변경 파일 확인
git diff --check                # 공백 오류 확인
git add <변경한 파일>
git commit -m "<변경 요약>"
git push origin <작업 브랜치>    # 이후 PR/MR로 main에 병합
```

참가자는 `main`을 Clone하므로, 병합 전에는 변경 내용이 참가자에게 보이지 않습니다.

GitHub 반영 후 Databricks Git folder에서 다음을 선택합니다.

- Git folder 메뉴 &gt; Pull 또는 Update
- Branch: main

참가자는 각자의 Free Edition Workspace에서 같은 public repository를 Clone하고, `cafe_training`, `cafe_hands_on` 등 문서의 이름을 그대로 사용합니다. 자세한 준비 절차는 [시작하기](../00_start_here.md)에 있습니다.

---

[← 4부 심화 실습](4_advanced.md) · [목차](README.md)
