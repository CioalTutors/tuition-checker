// ==========================================================
// CioalTutors Configuration
// ==========================================================
// Paste your Supabase project credentials here.
// You can find these in: Supabase Dashboard -> Project Settings -> API
// ==========================================================

const APP_CONFIG = {
  // Your Supabase Project URL
  SUPABASE_URL: "https://jjhuycugmwsqcmpzsihi.supabase.co",

  // Your Supabase Anon / Public Key
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqaHV5Y3VnbXdzcWNtcHpzaWhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzNDgyMDQsImV4cCI6MjEwNzkyNDIwNH0.kjl64KanuCdDws43SJxmZUjQ0QiafGlNtxIQ3VyICRw",

  // Target WhatsApp phone number for applications (country code without '+')
  WHATSAPP_NUMBER: "923459069492",

  // Admin emails who have full access to the Admin Dashboard
  ADMIN_EMAILS: ["cambridgeigcseoaleveltutors@gmail.com"]
};

// Check if credentials have been saved via browser settings modal
try {
  const localUrl = localStorage.getItem("cioal_supabase_url");
  const localKey = localStorage.getItem("cioal_supabase_key");
  if (localUrl && localKey) {
    APP_CONFIG.SUPABASE_URL = localUrl;
    APP_CONFIG.SUPABASE_ANON_KEY = localKey;
  }
} catch (e) {
  console.warn("Could not read localStorage for Supabase credentials", e);
}
