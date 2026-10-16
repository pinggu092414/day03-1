-- restaurants 표 정의. 2026-10-16에 Supabase 프로젝트 day03-1에 마이그레이션 create_restaurants로 이미 적용했다.
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
  created_at timestamptz not null default now()
);

create index restaurants_created_at_idx on public.restaurants (created_at desc);

alter table public.restaurants enable row level security;

-- 로그인 없이 누구나 보기·추가·삭제만 가능. 수정(update) 정책은 만들지 않는다.
create policy "anyone can view restaurants"
  on public.restaurants for select
  to anon, authenticated
  using (true);

create policy "anyone can add restaurants"
  on public.restaurants for insert
  to anon, authenticated
  with check (true);

create policy "anyone can delete restaurants"
  on public.restaurants for delete
  to anon, authenticated
  using (true);

-- RLS가 막지 못하는 권한(truncate 등)까지 최소화
revoke all on public.restaurants from anon, authenticated;
grant select, insert, delete on public.restaurants to anon, authenticated;
