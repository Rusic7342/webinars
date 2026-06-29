# itscontentflow — webinar funnel

English webinar-registration landing + multichannel reminder automation.
Separate brand from Quiet Art Space (illusions) — its own repo, Vercel project, and Supabase project.

## Architecture

```
Landing (static HTML)  →  Supabase (leads)  →  n8n (cron brain)  →  Telegram + email (+ WhatsApp later)
   form: name+email                              decides who/when      Claude only writes the copy
   + browser timezone                            reads/writes state
   + Telegram opt-in screen
```

- **Supabase** = memory (leads, profiles, webinar times in UTC, per-channel sent flags).
- **n8n** = the brain: a Schedule Trigger runs every ~15 min, reads Supabase, sends whatever reminder step is "due", marks it sent.
- **Claude** = only phrases the message from the lead's profile. It never decides timing and never generates the join link/time (those are injected as fixed variables). Always keep a template fallback.

## Files

| Path | What |
|---|---|
| `index.html` | The landing. Form → Supabase, then swaps to a Telegram opt-in "thank you" state. |
| `config.js` | Public front-end config (Supabase URL + anon key, bot username, webinar slug). Safe to commit. |
| `supabase/schema.sql` | Tables + RLS. Run once in the Supabase SQL editor. |

## Setup (first launch)

1. **Supabase project**
   - Create a **new free organization** in Supabase (the 2-free-projects limit is per org; your existing org with дома + промты is full). New org → new free project `itscontentflow`.
   - SQL Editor → paste `supabase/schema.sql` → Run.
   - Insert your webinar row, e.g.:
     ```sql
     insert into webinars (slug, title, starts_at, join_url)
     values ('launch', 'Your AI has never met your client',
             '2026-07-15 17:00:00+00', 'https://zoom.us/j/...');
     ```
   - Project Settings → API → copy **Project URL** and **anon public** key.

2. **Telegram bot**
   - In Telegram, message **@BotFather** → `/newbot` → get the bot **username** and **token**.
   - Username goes in `config.js` (`TG_BOT`); the **token** goes into n8n only (never in this repo).

3. **Fill `config.js`** with the Supabase URL, anon key, bot username, and webinar slug.

4. **Deploy to Vercel**
   - New Vercel project → import this repo → Framework preset: **Other** (it's static, no build step) → Deploy.
   - Add your domain.

## Security note

`config.js` holds only **public** values. The Supabase **anon key is meant to be public** — Row Level Security (see `schema.sql`) is what protects the data: the landing can only INSERT a lead, nothing else. The **service_role key** and the **Telegram bot token** are secrets and live **only in n8n**.

## Next steps (not built yet)

- n8n workflow #1: Telegram opt-in bot (`/start <lead_id>` → write `tg_chat_id` to the lead).
- n8n workflow #2: reminders cron (compute due step → send via TG/email → mark sent).
- Bot profiling survey (level / goal) → segment-aware copy via Claude.
- EN reminder sequence copy + WhatsApp templates (phase 2).
