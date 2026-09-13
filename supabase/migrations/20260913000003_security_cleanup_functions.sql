-- 資安清理（Supabase 資安檢查 0028 未登入可執行 SECURITY DEFINER 函式、0011 search_path 未固定）
-- 目前沒有實際外洩（這些函式對未登入的人只會回空值），屬於縮小攻擊面的整理。

-- ── 1. 權限檢查函式：未登入不需要呼叫，收回 anon / PUBLIC ─────────────
-- 例外：worker.get_my_role 保留 anon。worker 各表的規則 roles=public，
--       未登入查詢時會呼叫它（回 null → 查不到），收回會讓查詢直接報錯。
revoke execute on function public.list_users()                from public, anon;
revoke execute on function public.is_owner()                  from public, anon;
revoke execute on function public.is_tool_owner(text)         from public, anon;
revoke execute on function public.current_tool_role(text)     from public, anon;
revoke execute on function oreo.get_my_role()                 from public, anon;
revoke execute on function oreo.case_has_receivable(uuid)     from public, anon;
revoke execute on function oreo.case_has_target(uuid, text)   from public, anon;
revoke execute on function oreo.case_status(uuid)             from public, anon;

grant execute on function
  public.list_users(), public.is_owner(), public.is_tool_owner(text), public.current_tool_role(text),
  oreo.get_my_role(), oreo.case_has_receivable(uuid), oreo.case_has_target(uuid, text), oreo.case_status(uuid)
to authenticated, service_role;

-- ── 2. 觸發器專用函式：任何人都不該直接呼叫 ────────────────────────
-- 觸發器觸發時不檢查執行權，收回不影響註冊、OREO 收貨等流程。
revoke execute on function public.handle_new_user()           from public, anon, authenticated;
revoke execute on function oreo.check_case_complete()         from public, anon, authenticated;
revoke execute on function oreo.derive_item_fields()          from public, anon, authenticated;
revoke execute on function oreo.sync_vendor_receive_target()  from public, anon, authenticated;

-- ── 3. 固定 search_path ────────────────────────────────────────────
-- 這 6 個函式內部都寫完整名稱（oreo.xxx / auth.uid()）或只用內建函式，設空字串不改變行為。
alter function oreo.set_updated_at()                 set search_path = '';
alter function oreo.track_item_insert()              set search_path = '';
alter function oreo.track_item_change()              set search_path = '';
alter function oreo.guard_and_stamp_receive()        set search_path = '';
alter function oreo.default_receive_target(text)     set search_path = '';
alter function questboard.guard_sort_order()         set search_path = '';
