// itscontentflow — public front-end config.
// These values are PUBLIC by design (the anon key is safe to expose; Row Level
// Security in Supabase is what actually protects the data). Do NOT put the
// service_role key here — that one lives only in n8n.
//
// Fill these in after you create the Supabase project and the Telegram bot.
window.ICF_CONFIG = {
  // Supabase (beyond promts project — shared DB, webinar_* tables)
  SUPABASE_URL: 'https://coxzeqtgtokfsrfnzxwn.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNveHplcXRndG9rZnNyZm56eHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MTUzMzUsImV4cCI6MjA5NTI5MTMzNX0.zqzt536-Q71JPUNmiXypYMxKpy1Auci19BF6ko4MeNg',

  // Telegram bot username (without the @). Created via @BotFather.
  // Token is a SECRET — it lives only in n8n, never here.
  TG_BOT: 'webinar_M_bot',

  // Which webinar this landing registers people for (matches webinars.slug).
  WEBINAR_SLUG: 'launch',

  // n8n webhook that sends the welcome email (WF#3). Public URL is fine.
  N8N_WEBHOOK: 'https://tasks.itscontentflow.com/webhook/webinar-signup'
};
