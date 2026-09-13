-- Portal 使用者管理頁要能設定工廠關卡角色：
-- 任一工具 owner（public.is_owner()）也能增刪改 factoryboard.app_user。
-- 工廠關卡原本「自己的 owner 才能改」的規則保留不動（policy 之間是「或」）。

create policy app_user_insert_portal_owner on factoryboard.app_user
  for insert to authenticated
  with check ((select public.is_owner()));

create policy app_user_update_portal_owner on factoryboard.app_user
  for update to authenticated
  using ((select public.is_owner()))
  with check ((select public.is_owner()));

create policy app_user_delete_portal_owner on factoryboard.app_user
  for delete to authenticated
  using ((select public.is_owner()));
