-- 資安收緊：「登入就能讀」改成「有該工具角色才能讀」
-- 背景：Portal 開放申請帳號，陌生人註冊驗證後（沒被開通）原本就能讀工廠工單、客戶、OREO 廠商、Worker 回報照片；
--       未登入的人還能列出 mission、raw-images、factoryboard 照片空間的檔案清單。
-- 照片空間維持 public bucket：知道確切連結仍可看圖（各工具都用固定連結顯示，不受影響），只是不能再列清單。
-- Worker 上傳照片用 upsert，需要讀取權限，所以 report／mission 保留給有 worker 角色的人。

-- ── 1. 工廠關卡：有工廠角色才能讀 ──────────────────────────
alter policy customer_select      on factoryboard.customer           using ((select factoryboard.my_role()) is not null);
alter policy setting_select       on factoryboard.setting            using ((select factoryboard.my_role()) is not null);
alter policy telegram_chat_select on factoryboard.telegram_chat      using ((select factoryboard.my_role()) is not null);
alter policy work_order_select    on factoryboard.work_order         using ((select factoryboard.my_role()) is not null);
alter policy item_select          on factoryboard.work_order_item    using ((select factoryboard.my_role()) is not null);
alter policy wos_select           on factoryboard.work_order_station using ((select factoryboard.my_role()) is not null);

-- 名單、關卡清單：Portal 使用者管理頁也要讀（任一工具 owner）
alter policy app_user_select on factoryboard.app_user
  using ((select factoryboard.my_role()) is not null or (select public.is_owner()));
alter policy station_select on factoryboard.station
  using ((select factoryboard.my_role()) is not null or (select public.is_owner()));

-- ── 2. OREO 廠商：有 OREO 角色才能讀 ─────────────────────────
alter policy "all authenticated read vendors" on oreo.vendors rename to "oreo role read vendors";
alter policy "oreo role read vendors" on oreo.vendors using ((select oreo.get_my_role()) is not null);

-- ── 3. 照片空間：不再開放未登入／無角色的人列清單 ──────────────
drop policy "public read mission photos" on storage.objects;
create policy "mission read worker_role" on storage.objects
  for select to authenticated
  using (bucket_id = 'mission' and (select public.current_tool_role('worker')) is not null);

drop policy "authenticated users can view report photos" on storage.objects;
create policy "report read worker_role" on storage.objects
  for select to authenticated
  using (bucket_id = 'report' and (select public.current_tool_role('worker')) is not null);

drop policy factoryboard_image_read on storage.objects;
create policy factoryboard_image_read on storage.objects
  for select to authenticated
  using (bucket_id = 'factoryboard' and (select factoryboard.my_role()) is not null);

-- raw-images：舊 ELSA 殘留、現行 App 未使用，只留 owner
drop policy "raw-images select" on storage.objects;
create policy "raw-images read owner" on storage.objects
  for select to authenticated
  using (bucket_id = 'raw-images' and (select public.is_owner()));
