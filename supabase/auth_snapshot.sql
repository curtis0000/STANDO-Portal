-- ============================================================
-- STANDO 帳號系統 現行定義快照（2026-09-13 從 Supabase 資料庫匯出）
-- 專案：jpzgueafidiwmdosivxa
--
-- ⚠️ 參考用，不要整份重跑。之後的變更請另開檔案放 supabase/migrations/。
-- 早期定義散在 ELSA2.0/supabase/migrations/0014–0016、worker 等專案，
-- 部分只在資料庫裡沒有本機檔案，一律以這份快照為準。
-- ============================================================


-- ── 1. 帳號資料表 public.profiles（一對一對應 auth.users）──────────

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email        text constraint profiles_email_unique unique,
  phone        text,
  department   text,
  is_active    boolean default true,          -- false = 全工具擋掉（工廠關卡除外，見 §5）
  tool_roles   jsonb not null default '{}'::jsonb,  -- 例：{"elsa":"owner","oreo":"office"}
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
alter table public.profiles enable row level security;


-- ── 2. 註冊時自動建 profiles（tool_roles 為空 = 待開通）─────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name')
  on conflict (id) do nothing;
  return new;
end;
$function$;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- ── 3. 權限函式（RLS 用）────────────────────────────────────────

-- 目前登入者在某工具的角色；帳號停用時回 NULL
CREATE OR REPLACE FUNCTION public.current_tool_role(tool text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select p.tool_roles ->> tool
  from public.profiles p
  where p.id = auth.uid()
    and coalesce(p.is_active, true);
$function$;

-- 是否為「指定工具」的 owner
CREATE OR REPLACE FUNCTION public.is_tool_owner(tool text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select coalesce(public.current_tool_role(tool) = 'owner', false);
$function$;

-- 是否為「任一工具」的 owner —— 帳號管理用這個
CREATE OR REPLACE FUNCTION public.is_owner()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and coalesce(p.is_active, true)
      and exists (
        select 1 from jsonb_each_text(p.tool_roles) e where e.value = 'owner'
      )
  );
$function$;

-- Portal 使用者管理頁列出所有人（含 auth.users 的 email）
CREATE OR REPLACE FUNCTION public.list_users()
 RETURNS TABLE(id uuid, email text, display_name text, department text, tool_roles jsonb, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
  select p.id, u.email::text, p.display_name, p.department, p.tool_roles, p.created_at
  from public.profiles p
  join auth.users u on u.id = p.id
  where public.is_owner()
  order by p.created_at;
$function$;


-- ── 4. profiles 存取規則 ────────────────────────────────────────

create policy profiles_select_self  on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_select_owner on public.profiles for select to authenticated using (is_owner());
create policy profiles_write_owner  on public.profiles for all    to authenticated using (is_owner()) with check (is_owner());

-- 各工具為了顯示人名，自己加的讀取規則（定義在各工具專案）
create policy worker_app_select     on public.profiles for select to authenticated using (worker.get_my_role() is not null);
create policy questboard_app_select on public.profiles for select to authenticated using ((select questboard.my_role()) is not null);

-- 各工具包一層讀自己的 key
--   worker.get_my_role()   = public.current_tool_role('worker')
--   questboard.my_role()   = public.current_tool_role('questboard')


-- ── 5. 工廠關卡（factoryboard）：自己的名單，不走 tool_roles ──────

-- create table factoryboard.app_user (
--   id         uuid primary key references auth.users(id) on delete cascade,
--   name       text not null,
--   role       text not null check (role in ('owner','office','manager','station')),  -- manager 原名 boss
--   station_id text references factoryboard.station(id),   -- role = station 時必填，其餘必須為空
--   created_at timestamptz not null default now()
-- );
--
-- factoryboard.my_role()：service_role 回 'system'，否則讀 app_user.role
--   ⚠️ 不看 profiles.is_active，所以 Portal 停用帳號擋不到工廠關卡
--
-- app_user 規則：
--   app_user_select                  有工廠角色或任一工具 owner 可讀（見 migrations/20260913000002）
--   app_user_insert/update/delete    工廠關卡自己的 owner
--   app_user_*_portal_owner          任一工具 owner（Portal 管理頁用，見 migrations/20260913000001）
