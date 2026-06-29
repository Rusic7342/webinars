# n8n workflows — itscontentflow

Import these into your n8n (the Oracle instance). Secrets (bot token, Supabase
service_role key) live in n8n **credentials**, never in these JSON files.

## Credentials to create first (n8n → Credentials → New)

1. **Telegram API** — name it exactly `webinar_M_bot`
   - Access Token = the bot token from @BotFather.

2. **Supabase API** — name it exactly `Supabase Beyond Promts (service_role)`
   - Host = `https://coxzeqtgtokfsrfnzxwn.supabase.co`
   - Service Role Secret = the **`service_role`** key
     (Supabase → Project Settings → API → `service_role`, the SECRET one — not `anon`).

The node JSON references these credentials by the exact names above, so matching
names means import "just works".

## 01 — Telegram opt-in (`01-telegram-optin.json`)

What it does: when a lead taps the "Connect Telegram" button on the site, Telegram
opens the bot with `/start <lead_id>`. This workflow:
1. parses the `lead_id` from `/start`,
2. writes `tg_chat_id` + `tg_connected_at` onto that lead in Supabase,
3. replies with a confirmation. (No valid `lead_id` → asks them to register first.)

### Import & activate
1. n8n → Workflows → **Import from File** → pick `01-telegram-optin.json`.
2. Open any node showing a credential warning → select the credential created above.
3. Toggle the workflow **Active** (top-right). Activating registers the Telegram webhook.
   - Your n8n must be reachable on a public **HTTPS** URL for the webhook to work.

### Test
1. Get a real lead id from Supabase (SQL editor):
   ```sql
   select id, email from webinar_leads order by created_at desc limit 1;
   ```
2. Open in a browser: `https://t.me/webinar_M_bot?start=<that-id>` → press **Start**.
3. Expect: a confirmation message in Telegram, and the lead's `tg_chat_id` now filled:
   ```sql
   select email, tg_chat_id, tg_connected_at from webinar_leads where id = '<that-id>';
   ```

## Next (not built yet)
- `02-reminders-cron.json` — Schedule Trigger every ~15 min: compute the due step
  relative to `webinars.starts_at`, send via Telegram/email to leads missing that step,
  mark `steps_sent`.
- Bot profiling survey (level / goal buttons) appended after the opt-in confirmation.
