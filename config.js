// itscontentflow — public front-end config.
// These values are PUBLIC by design (the anon key is safe to expose; Row Level
// Security in Supabase is what actually protects the data). Do NOT put the
// service_role key here — that one lives only in n8n.
//
// Fill these in after you create the Supabase project and the Telegram bot.
window.ICF_CONFIG = {
  // Supabase → Project Settings → API
  SUPABASE_URL: 'https://YOUR-PROJECT.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_ANON_PUBLIC_KEY',

  // Telegram bot username (without the @). Created via @BotFather.
  TG_BOT: 'YourBotUsername',

  // Which webinar this landing registers people for (matches webinars.slug).
  WEBINAR_SLUG: 'launch'
};
