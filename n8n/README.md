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

## 02 — Reminders cron, Telegram (`02-reminders-cron.json`)

Sends timed Telegram reminders so people actually show up. Every 15 min it:
1. gets the next upcoming webinar (`starts_at` within the future / last 30 min),
2. computes which step is **due** by minutes-to-start:
   `day_before` (24h–3h) · `soon_3h` (3h–1h) · `hour_before` (1h–15m) · `fifteen_min` (15m–0) · `live` (0 to −20m),
3. fetches TG-connected leads who haven't gotten that step (`steps_sent` not contains it),
4. sends the message — webinar time rendered in **each lead's timezone**,
5. calls `mark_tg_step(lead, step)` to record it (idempotent, no double-sends).

### Prerequisite
Run `supabase/02-reminders-functions.sql` once (SQL Editor) to create `mark_tg_step`.

### Import
Same as WF#1: Import from File → map the two credentials (Telegram `webinar_M_bot`,
Supabase `Supabase Beyond Promts (service_role)`) → **activate**.

### Test (without waiting for the real date)
1. Temporarily set a webinar ~10–15 min out so a step is "due":
   ```sql
   update webinars set starts_at = now() + interval '12 minutes' where slug = 'launch';
   ```
2. Make sure you have a TG-connected test lead (one with `tg_chat_id`, e.g. yourself via the opt-in link).
3. In the workflow, click **Execute workflow** (don't wait for the 15-min tick).
4. Expect a Telegram reminder + the lead's `steps_sent` now contains the step:
   ```sql
   select email, steps_sent, tg_sent from webinar_leads where tg_chat_id is not null;
   ```
5. Run it again → it should NOT resend (idempotent). Reset the date afterwards.

## 03 — Welcome email (`03-welcome-getresponse.json`)

Sends the instant welcome email when someone registers. Triggered by the landing form
(fire-and-forget `fetch` to this webhook), NOT by the cron — so the email goes out immediately.

Flow: Webhook (`/webhook/webinar-signup`) → looks up the GetResponse campaign id (by name
"Webinar") and the custom-field id (by name "bot_lead_id") → adds the contact to the list with
`bot_lead_id` = the lead's id. A GetResponse **Day-0 autoresponder** then sends the actual email
(`emails/welcome.md`), which builds the personal bot link from `[[bot_lead_id]]`.

### GetResponse setup (one-time)
1. Create a new **list (campaign)** named exactly **`Webinar`** (separate from the prompts list — do NOT use ukcj0).
2. Create a **custom field** named exactly **`bot_lead_id`** (type: text/single line).
3. Create an **autoresponder** on the `Webinar` list, **Day 0**, paste `emails/welcome.md` (subject + body), style it.
4. Get your **API key**: GetResponse → Integrations & API → API → generate key.

### n8n credential
Create a **Header Auth** credential named **`GetResponse API`**:
- Name: `X-Auth-Token`
- Value: `api-key YOUR_GETRESPONSE_API_KEY`  ← note the literal `api-key ` prefix

### Import & activate
Import `03-welcome-getresponse.json` → map the `GetResponse API` credential on all 3 HTTP nodes →
**activate**. The webhook URL becomes `https://tasks.itscontentflow.com/webhook/webinar-signup`
(already set in the landing's `config.js`).

### Test
Submit the form on the live site with a real email → within seconds the contact appears in the
`Webinar` list with `bot_lead_id` set → the Day-0 autoresponder sends the welcome.

## Next (not built yet)
- Email reminders via **Resend** (per-lead, anchored to webinar date) — add to WF#2 alongside Telegram.
- `templates` table in Supabase = editable battery of copy per channel/step/segment; n8n picks + (later) Claude personalizes.
- Bot profiling survey (level / goal buttons) appended after the opt-in confirmation.
- Post-webinar branch: `attended` flag from Zoom → replay (no-show) / offer (attended).
