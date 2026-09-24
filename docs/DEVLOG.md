# DEVLOG
> 只記決策與理由、試過但放棄、踩過的坑。做了什麼看 git log。

## 2026-09-23 註冊引導修正
- 坑：新人註冊後沒點確認信，管理員把權限全開了仍登不進去。各工具登入頁只顯示「帳號或密碼不對」，管理頁也看不出信箱未驗證，兩邊都無從察覺。
- 決策：list_users() 多回傳 email_confirmed_at，管理頁標「未驗證信箱」。回傳型別有變，CREATE OR REPLACE 不行，要先 DROP 再建並重下授權。
- 坑：Supabase 對已註冊的 Email 再 signUp 不報錯也不寄信（防探測帳號），只回一個 identities 為空的假使用者。前端靠 identities 長度為 0 判斷，改提示「已有帳號」。
- 決策：手動把使用者標成已驗證（直接改 auth.users）只當救急手段，正規流程仍是點確認信；當天對方自己點完了，沒動到。
- 坑：用 Supabase MCP 套 migration 會被 Claude Code 自動權限擋（判定為正式環境部署），要使用者明說「套用」再重試一次才過。
