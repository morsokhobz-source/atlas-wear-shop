// Public browser config only. Never put a Supabase service_role secret here.
// Replace the two values after creating the Supabase project. The anon/publishable key is designed for browser use; database RLS policies protect the data.
window.SHOP_CONFIG = {
  supabaseUrl: "PASTE_SUPABASE_PROJECT_URL_HERE",
  supabaseAnonKey: "PASTE_SUPABASE_ANON_OR_PUBLISHABLE_KEY_HERE"
};
