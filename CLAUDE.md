# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고할 안내를 담고 있다.

## 현재 상태

아직 코드가 없다. 저장소에는 기획 문서 두 개만 있다. 구현하기 전에 반드시 읽을 것:

- [PRD.md](PRD.md) — 무엇을 만드는지 (기능, 입력 규칙, 표 구조, 보안, 완료 기준)
- [STEPS.md](STEPS.md) — 만드는 순서. 4단계(맛집 기록 → Supabase 저장 → AI 한줄평 → 배포)이며, 앞 단계의 "완료 확인"을 통과한 뒤 다음 단계로 간다. 단계가 끝날 때마다 커밋한다.

문서와 화면 문구는 모두 한국어다. 사용자는 "코드는 아직 만들지 마"처럼 단계를 끊어서 지시하므로, 요청받은 단계 밖의 구현을 미리 하지 않는다.

## 명령어

빌드·린트·테스트 명령은 없다. npm, 번들러, 테스트 러너를 쓰지 않기로 했다(PRD 12절). `index.html`을 브라우저에서 열어 확인한다.

Windows에서 winget으로 Git을 설치했기 때문에, 이미 열려 있던 셸에서는 `git`이 인식되지 않을 수 있다. 그때는 `& "C:\Program Files\Git\cmd\git.exe"`로 실행하거나 새 셸을 연다.

## 구조 (여러 파일을 봐야 보이는 큰 그림)

앱은 `index.html` 하나(화면·스타일·동작 전부) + Supabase Edge Function 1개(`supabase/functions/suggest-review/index.ts`, 이름은 제안값)로 이루어진다.

- **저장소는 교체하지 섞지 않는다.** 1단계는 localStorage, 2단계에서 Supabase `restaurants` 표로 *바꾼다*. 둘을 동시에 쓰지 않는다. 그래서 1단계 기록은 처음부터 표와 같은 열 이름(`id, name, menu, rating, review, created_at`)의 배열로 저장해 2단계 교체를 쉽게 한다.
- **검증은 두 곳에서 한다.** 이름 1~30자(필수), 메뉴 ≤30자, 별점 1~5(필수), 한줄평 ≤100자 규칙을 화면에서도, 표 CHECK 제약에서도 막는다. 한쪽만 바꾸면 둘이 어긋나므로 규칙을 바꿀 때는 `index.html`과 표 제약을 함께 고친다.
- **로그인이 없다.** RLS는 켜되 anon에게 보기·추가·삭제만 허용하고 수정(UPDATE) 정책은 만들지 않는다(수정 기능이 범위 밖). 새 표를 만들고 기존 표는 건드리지 않는다.
- **비밀 값 경계.** 브라우저 코드(`index.html`)에는 Supabase URL과 공개(anon/publishable) 키만 둔다. service_role 키는 어디에도 두지 않는다. OpenRouter 키는 Supabase Secrets `openrouter_apl_key`에만 있고 Edge Function이 읽는다. 이름은 사용자가 쓴 그대로이며 "api"의 오타일 수 있으니, 함수가 읽는 이름과 Secrets 이름이 정확히 같은지 확인한다.
- **Edge Function은 `verify_jwt`를 끄고 배포한다.** 누구나 호출할 수 있으므로 입력 길이를 제한하고 한줄평 생성 외의 일은 하지 않는다. 모델을 `nvidia/nemotron-3-ultra-550b-a55b:free` → `google/gemma-4-26b-a4b-it:free` → `google/gemma-4-31b-it:free` 순서로 시도하고, 결과가 40자를 넘지 않도록 함수 쪽에서 보장한다. 이 모델 ID가 OpenRouter에 실제로 있는지는 3단계 시작 때 확인한다.
- **사용자 입력은 글자 그대로 그린다.** 누구나 글을 쓸 수 있는 앱이라, 이름·메뉴·한줄평을 `innerHTML`로 넣지 않고 텍스트로 넣는다(`textContent` 등).
- **하지 않을 것:** 로그인, 수정, 사진 업로드, 검색. 요청이 없으면 넣지 않는다.

## 배포

GitHub에 올려 Vercel로 배포하는 빌드 없는 정적 사이트다. Vercel에 빌드 명령을 설정하지 않는다.
