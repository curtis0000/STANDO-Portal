-- list_users() 多回傳 email_confirmed_at，讓 admin.html 看得出誰還沒點確認信。
-- 起因：2026-09-23 管理員開好權限，對方卻因沒驗證信箱登不進去，管理頁看不出來。
-- 回傳型別有變，CREATE OR REPLACE 不允許，要先 DROP 再建，授權照 20260913000003 重設。

drop function if exists public.list_users();

create function public.list_users()
 returns table(id uuid, email text, display_name text, department text, tool_roles jsonb, created_at timestamptz, email_confirmed_at timestamptz)
 language sql
 stable security definer
 set search_path to 'public', 'auth', 'pg_temp'
as $function$
  select p.id, u.email::text, p.display_name, p.department, p.tool_roles, p.created_at, u.email_confirmed_at
  from public.profiles p
  join auth.users u on u.id = p.id
  where public.is_owner()
  order by p.created_at;
$function$;

revoke execute on function public.list_users() from public, anon;
grant  execute on function public.list_users() to authenticated, service_role;
