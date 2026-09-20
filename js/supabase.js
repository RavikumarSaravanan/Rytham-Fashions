const SUPABASE_URL = "https://mjazdmolasuouxggrjkm.supabase.co";
const SUPABASE_PUBLISHABLE_KEY =
  "sb_publishable_M-2GJSAW2VjhzzxNZgmLXA_W7r5e8tz";

const supabaseClient = window.supabase.createClient(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY,
);
