# PROGRESS
> 一行：只放現況與接下來；歷史在 docs/DEVLOG.md，規則在 權限整合.md。

## 當前游標
**2026-10-15：首頁下架 CHEF 卡片、加 STANDO ERP 概念圖卡片，已 commit c302b25，工作樹乾淨**
- CHEF 只拿掉首頁卡片與 `chef_url`；admin.html 的 chef 角色欄與資料庫不動
- ERP 概念圖卡片連 https://stando-erp.vercel.app ，不用登入
驗證：本機開 index.html 剩七張卡

## 接下來
**等用戶**：無
**待做**：
1. 各工具（ELSA、Worker、OREO…）自己的登入頁也區分「信箱未驗證」，目前只有 Portal 首頁有
2. 權限整合.md §5 既有待辦：ELSA 前端沒檢查 is_active；pricemana、auth-reset 未整合 tool_roles

## 怎麼跑、怎麼驗收
純靜態 HTML，直接開檔即可。推上 GitHub main 後由 GitHub Pages 自動發布：
https://curtis0000.github.io/STANDO-Portal/ （通常 30 秒內生效）
資料庫變更：寫進 `supabase/migrations/`，再用 Supabase MCP 或 Dashboard SQL Editor 套用。

## 已知取捨與未做
- 管理頁「未驗證信箱」判斷用 `=== null`，migration 沒套時欄位是 undefined 不會誤標
- 停用帳號擋不到工廠關卡（獨立名單），要擋請把工廠關卡設「（無權限）」

## 近期紀錄
- 2026-10-15：首頁下架 CHEF 卡片（c302b25）
- 2026-10-15：首頁加 STANDO ERP 概念圖卡片（b72e3ad）
- 2026-09-23：註冊／登入／管理頁信箱驗證引導修正（a2e7390）
- 2026-09-13：資安清理，收回未登入呼叫權限函式（78e010a）
- 2026-09-13：讀取一律要求有該工具角色；管理頁 ELSA 欄標 2.0／3.0（ab28ef1）
- 2026-09-13：管理頁集中管理工廠關卡角色與待開通區（54d2a8b）

## 環境快照
靜態 HTML + supabase-js v2（CDN）；Supabase 專案 jpzgueafidiwmdosivxa；GitHub Pages（main 分支根目錄）
