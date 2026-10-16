-- restaurants 표 정의 (지금 적용된 최종 모습). Supabase 프로젝트 day03-1에 이미 적용했다.
--   2026-10-16 create_restaurants         표·제약·RLS 만들기 (처음에는 anon도 보기·추가·삭제 허용)
--   2026-10-16 restaurants_require_login  로그인한 사람(authenticated)만 허용으로 변경, anon 권한 회수
--   2026-10-16 restaurants_add_area_address  지역(area)·주소(address) 열 추가 (아래 create table에는 합쳐서 적었다)
-- 이미 적용돼 있으니 다시 실행하지 말고, 바꿀 때는 마이그레이션으로 바꾼 뒤 이 파일도 맞춘다.
-- 규칙(글자 수·별점 범위)을 바꾸면 index.html의 LIMITS / validateField도 함께 고칠 것.

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null
    constraint restaurants_name_len check (char_length(name) between 1 and 30 and btrim(name) <> ''),
  menu text not null default ''
    constraint restaurants_menu_len check (char_length(menu) <= 30),
  rating smallint not null
    constraint restaurants_rating_range check (rating between 1 and 5),
  review text not null default ''
    constraint restaurants_review_len check (char_length(review) <= 100),
  created_at timestamptz not null default now(),
  -- 카드에 마우스를 올리면 나오는 지도에 쓴다. 비워 두면 ''
  area text not null default ''
    constraint restaurants_area_len check (char_length(area) <= 30),
  address text not null default ''
    constraint restaurants_address_len check (char_length(address) <= 100)
);

create index restaurants_created_at_idx on public.restaurants (created_at desc);

alter table public.restaurants enable row level security;

-- 로그인한 사람(authenticated)만 보기·추가·삭제. 로그인하지 않은 사람(anon)은 아무것도 못 한다.
-- 수정(update) 정책은 만들지 않는다.
create policy "signed-in users can view restaurants"
  on public.restaurants for select
  to authenticated
  using (true);

create policy "signed-in users can add restaurants"
  on public.restaurants for insert
  to authenticated
  with check (true);

create policy "signed-in users can delete restaurants"
  on public.restaurants for delete
  to authenticated
  using (true);

-- RLS가 막지 못하는 권한(truncate 등)까지 최소화
revoke all on public.restaurants from anon, authenticated;
grant select, insert, delete on public.restaurants to authenticated;
