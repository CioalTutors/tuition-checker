# CioalTutors Portal

A modern web application for **CioalTutors.com** allowing teachers to sign in with Google/Gmail, browse live open tuitions, and apply directly via WhatsApp. Includes a dedicated **Admin Dashboard** for administrators to add, edit, open, close, and manage tuition postings in real-time.

---

## 🌟 Key Features

1. **Teacher Google / Gmail Authentication**:
   - Teachers log in with Google to view live tuition details.
   - Profile avatar and identity automatically extracted.
2. **Teacher View**:
   - Live feed of **Open** tuitions (newest first).
   - Realtime updates: newly posted tuitions appear instantly without refreshing.
   - Instant search across subjects, class, area/city, and tuition number.
   - 1-click **Apply Now** button opening WhatsApp with pre-filled application details.
3. **Dedicated Admin Dashboard**:
   - Add new tuitions with subjects, class, area/city, and full requirements.
   - Instant status toggle between **Open** and **Closed**.
   - Edit and delete existing postings.
   - Filter by status (`All`, `Open`, `Closed`).
   - Protected by Supabase Row Level Security (RLS).

---

## 🚀 Setup Guide

### 1. Run the Supabase SQL Schema
1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to the **SQL Editor** on the left menu.
3. Open `supabase-schema.sql` from this repository, copy all the SQL, and paste it into the query editor.
4. Click **Run**.
   - This creates the `profiles` and `tuitions` tables, security definer triggers, and RLS policies.

---

### 2. Configure Google OAuth in Supabase
1. In your Supabase Dashboard, go to **Authentication &rarr; Providers &rarr; Google**.
2. Enable the Google provider.
3. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
   - Create an **OAuth 2.0 Client ID** (Web Application).
   - Under **Authorized redirect URIs**, add your Supabase Callback URL (found in Supabase under Google Provider settings, formatted like `https://<YOUR-PROJECT-REF>.supabase.co/auth/v1/callback`).
   - Copy the **Client ID** and **Client Secret** into Supabase and click **Save**.
4. In Supabase under **Authentication &rarr; URL Configuration**:
   - Set **Site URL** to your app's URL (e.g. `http://localhost:3000` or your GitHub Pages URL).

---

### 3. Connect the Web App
Open `config.js` and paste your project credentials from **Supabase Dashboard &rarr; Project Settings &rarr; API**:

```javascript
const APP_CONFIG = {
  SUPABASE_URL: "https://your-project-id.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi...",
  WHATSAPP_NUMBER: "923459069492"
};
```
*(Alternatively, when you open `index.html` in your browser, a prompt will let you paste your Supabase URL and Key directly).*

---

### 4. How to Make Yourself an Admin
1. Open the app in your browser and click **Continue with Google** using your admin Gmail.
2. Once signed in, go to the **SQL Editor** in Supabase and run:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'your_admin_email@gmail.com';
```

3. Refresh the web page. Your role badge will now display **Admin**, and the **Admin Panel** tab will appear in the navigation bar!
