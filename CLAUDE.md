# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고할 안내를 담고 있다.

## 현재 상태

1~3단계(맛집 기록, Supabase 저장, AI 한줄평)가 끝났고, 4단계(배포)가 남았다. 구현하기 전에 반드시 읽을 것:

- [PRD.md](PRD.md) — 무엇을 만드는지 (기능, 입력 규칙, 표 구조, 보안, 완료 기준)
- [STEPS.md](STEPS.md) — 만드는 순서. 4단계(맛집 기록 → Supabase 저장 → AI 한줄평 → 배포)이며, 앞 단계의 "완료 확인"을 통과한 뒤 다음 단계로 간다. 단계가 끝날 때마다 커밋한다.

문서와 화면 문구는 모두 한국어다. 사용자는 "2단계 실행해줘"처럼 단계를 끊어서 지시하므로, 요청받은 단계 밖의 구현을 미리 하지 않는다.

## 명령어

빌드·린트·테스트 명령은 없다. npm, 번들러, 테스트 러너를 쓰지 않기로 했다(PRD 12절).

이 PC에는 python과 node가 없다. 동작 확인은 `index.html`을 Chrome/Edge로 직접 열거나, PowerShell `System.Net.HttpListener`로 `http://localhost`에 임시 서버를 띄워서 한다. Claude 앱의 미리보기 창은 파일을 `data:` 주소의 정적 스냅샷으로 열기 때문에 동작 확인에 쓰지 않는다.

Windows에서 winget으로 Git을 설치했기 때문에, 이미 열려 있던 셸에서는 `git`이 인식되지 않을 수 있다. 그때는 `& "C:\Program Files\Git\cmd\git.exe"`로 실행하거나 새 셸을 연다. 이 저장소에는 git 작성자(user.name/email)가 설정돼 있지 않다.

## 구조 (여러 파일을 봐야 보이는 큰 그림)

앱은 `index.html` 하나(화면·스타일·동작 전부) + Supabase Edge Function 1개(`supabase/functions/suggest-review/index.ts`, 화면의 [AI 한줄평 추천] 버튼이 부른다)로 이루어진다.

- **저장소는 Supabase `restaurants` 표 하나다.** 2단계에서 localStorage를 *교체*했고 둘을 섞지 않는다(예전 localStorage 기록은 옮기지 않았다). 저장소와 통신하는 코드는 `index.html`의 `api()`와 `listRestaurants` / `addRestaurant` / `removeRestaurant` 뿐이다(supabase-js 없이 REST `fetch`). `api()`는 로그인 토큰을 `Authorization`에 붙이고, 401이면 한 번 갱신해서 다시 보낸다. 화면 코드는 이 세 함수만 부른다. 열은 `id, name, menu, rating, review, created_at, area, address`이고, 목록 정렬(`created_at` 내림차순)은 서버가 한다.
- **Supabase 프로젝트는 `day03-1`** (ref `leppiltvaejxpodopijj`, ap-northeast-2)이고 표 정의는 [supabase/restaurants.sql](supabase/restaurants.sql)에 있다. 이미 적용돼 있으니 다시 실행하지 말고, 표를 바꿀 때는 마이그레이션으로 바꾼 뒤 이 파일도 맞춘다.
- **검증은 두 곳에서 한다.** 이름 1~30자(필수), 메뉴 ≤30, 별점 1~5(필수), 한줄평 ≤100 규칙을 화면(`LIMITS`, `validateField`)에서도, 표 CHECK 제약에서도 막는다. 글자 수는 둘 다 코드 포인트 기준이다(`Array.from`, `char_length`). 규칙을 바꿀 때는 둘을 함께 고친다.
- **표는 로그인한 사람만 쓴다.** RLS 정책은 `authenticated`에게만 보기·추가·삭제를 주고, `anon`은 권한 자체를 회수했다. 수정(UPDATE) 정책은 없고 truncate 등 나머지 권한도 회수했다. 화면에서 목록·입력창을 숨기는 것은 보조이고 진짜 차단은 표가 한다. 처음에는 anon도 허용했다가 `restaurants_require_login` 마이그레이션으로 바꿨다. 로그인 없이 공개 키로 표를 읽으면 `401 permission denied`가 나야 정상이다. 새 표를 만들어 썼고 기존 표는 건드리지 않았다.
- **가입·로그인·로그아웃은 Supabase Auth REST로 직접 한다**(`index.html`의 `authFetch`, `signUp`, `logIn`, `logOut`, supabase-js 없음). 세션(`access_token`, `refresh_token`, `expires_at`, 이메일, 닉네임)은 localStorage의 `hidden-eats-session`에 두고, 비밀번호는 저장하지 않는다. 토큰은 만료 60초 전에 갱신한다. 로그인 여부로 화면을 바꾸는 곳은 `updateAuthView()` 하나이고, 로그인 전에는 맛집 입력창·목록(`#app`)을 숨기고 DOM의 목록도 비운다. 닉네임은 `user_metadata.nickname`에 있다.
- **인증 시험 방법.** 실제 가입·로그인은 계정이 만들어지고 메일이 나가서 자동 시험하지 않았다. 요청 내용과 오류 처리는 `fetch`를 가짜 응답으로 바꿔서 확인했고, 실제 서버로는 가짜 토큰을 보내 `401`과 갱신 거절 처리만 확인했다. 확인 메일이 일반 사용자에게 가려면 Supabase에서 메일 확인을 끄거나 SMTP를 연결하고, Auth 설정의 Site URL·Redirect URLs에 배포 주소를 넣어야 한다. AI 한줄평 함수는 처음 정한 대로 로그인 확인을 하지 않는다(`verify_jwt` 끔).
- **비밀 값 경계.** 브라우저 코드(`index.html`)에는 Supabase URL과 공개(publishable) 키만 둔다. service_role 키는 어디에도 두지 않는다. OpenRouter 키는 Supabase Secrets `openrouter_apl_key`에만 있고 Edge Function이 읽는다. 이름은 사용자가 쓴 그대로이며 "api"의 오타일 수 있어서, 함수는 `openrouter_apl_key`를 먼저 읽고 없으면 `openrouter_api_key`를 읽는다. 실제 호출로 키가 동작하는 것을 확인했다.
- **Edge Function은 `verify_jwt`를 끄고 배포한다.** 누구나 호출할 수 있으므로 입력 길이를 제한하고 한줄평 생성 외의 일은 하지 않는다. 모델을 `nvidia/nemotron-3-ultra-550b-a55b:free` → `google/gemma-4-26b-a4b-it:free` → `google/gemma-4-31b-it:free` 순서로 시도하고, 결과가 40자를 넘지 않도록 함수 쪽에서 보장한다. 모델 ID 3개는 OpenRouter 목록에 있는 것을 확인했다. 무료 모델이라 `429`·빈 응답·시간 초과가 잦아서(연속 8번 호출 중 1번 실패), 한 바퀴를 다 실패하면 한 번 더 돌고 전체를 35초로 끊는다. 그래도 실패하면 화면은 "직접 적어 주세요" 안내만 보여 준다. 함수 파일을 고쳐도 자동 반영되지 않으니 Supabase에 다시 배포하고(`verify_jwt: false` 유지), 실패 원인은 Supabase 로그의 `function_logs`에서 본다.
- **사용자 입력은 글자 그대로 그린다.** 누구나 글을 쓸 수 있는 앱이라, 이름·메뉴·한줄평을 `innerHTML`로 넣지 않고 텍스트로 넣는다(`textContent` 등).
- **디자인은 `DESIGN-mobbin.md`(저장소 밖, 사용자 Downloads 폴더)를 따른다.** 흰 바탕·잉크 `#141414` 모노크롬, 알약 버튼, 24px 카드, 그림자 없음. 처음의 주황색 포인트는 없앴다. 색은 `index.html`의 `:root` 변수로 모여 있고, 붉은색(`--error`)은 입력 오류에만 쓴다. Saans 글꼴은 없어서 시스템 한글 글꼴로 대체했다(가변 굵기 650/456/300은 가변 글꼴일 때만 먹는다). 새 화면을 만들 때도 이 규칙을 따르고 주황색이나 다른 강조색을 다시 넣지 않는다.
- **PC 배치와 쪽 나누기.** 로그인하면 `.page`에 `signed-in` 클래스가 붙고, 너비 1000px 이상에서만 CSS 격자(`grid-template-areas`)로 왼쪽 제목+입력창·오른쪽 목록으로 나뉜다. `.hero`와 `#app`은 `display: contents`라서 안의 요소가 격자에 바로 놓인다. PC에서는 `renderList()`가 한 번에 4곳만 그리고(`PC_PAGE_SIZE`), 좁은 화면에서는 전부 그린다. 1000px 기준이 CSS(`@media`)와 JS(`matchMedia`) 두 곳에 있으니 같이 바꾼다. 맨 아래 띠는 `position: sticky`다.
- **카드 지역·지도 말풍선.** 카드에 마우스를 올리면(`renderCard` → `attachMapPop`) `#map-pop`이 뜨고, 구글 지도의 키 없는 임베드(`maps.google.com/maps?q=...&output=embed`)를 그 순간에만 불러온다. 검색어는 `식당 이름 + (주소 또는 지역)`이다. `area`(짧은 지역 표시, 입력창에서 받음)와 `address`(도로명 주소, 입력창에는 없음)가 둘 다 비면 지도 대신 안내 문구만 나온다. 처음 20곳의 지역·주소는 카카오맵으로 확인해 채웠고, `잇탈리 헤이리`·`만돈`·`2리 식당`·`돈이와`는 가게를 못 찾아 주소를 비워 뒀다. 말풍선은 클릭을 받고(`pointer-events` 기본값), 카드에서 말풍선으로 건너가는 틈 때문에 닫기를 0.3초 미룬다(`scheduleHideMapPop`). 지도 아래 `[지도에서 열기 ↗]`는 구글 지도 검색 링크(새 탭)이고, 지도 안쪽의 구글 자체 버튼은 샌드박스 iframe이라 환경에 따라 안 열릴 수 있다. 구글이 이 임베드를 막으면 지도가 안 보이니, 그때는 공식 지도 API 키 방식으로 바꿔야 한다.
- **하지 않을 것:** 소셜 로그인, 비밀번호 찾기, 작성자별 삭제 제한, 수정, 사진 업로드, 검색. 요청이 없으면 넣지 않는다.

## 배포

GitHub(`pinggu092414/day03-1`, 브랜치 `master`)에 올려 Vercel로 배포하는 빌드 없는 정적 사이트다. Vercel에 빌드 명령을 설정하지 않는다.
