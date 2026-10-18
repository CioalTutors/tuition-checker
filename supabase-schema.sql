-- ==========================================================
-- CioalTutors Database Schema & Security Setup (Supabase)
-- ==========================================================
-- Instructions:
-- 1. Open your Supabase project dashboard: https://supabase.com/dashboard
-- 2. Go to "SQL Editor" in the left sidebar.
-- 3. Click "New query", paste this entire script, and click "Run".
-- ==========================================================

-- 1. PROFILES TABLE
-- Stores user information, avatars, and application roles ('teacher' or 'admin')
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'teacher' CHECK (role IN ('teacher', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. HELPER FUNCTION: Check if the current logged-in user is an admin
-- Uses SECURITY DEFINER to bypass RLS recursion safely
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 3. ROW LEVEL SECURITY (RLS) FOR PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. AUTO-CREATE PROFILE ON GOOGLE SIGN IN
-- Trigger automatically runs when a new user signs in with Google
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
    'teacher' -- default role is teacher
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. TUITIONS TABLE
-- Stores tuition postings with status, subjects, class, location, and full details
CREATE TABLE IF NOT EXISTS public.tuitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tuition_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  subjects TEXT NOT NULL,
  class_name TEXT NOT NULL,
  area_city TEXT NOT NULL,
  details TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 6. ROW LEVEL SECURITY (RLS) FOR TUITIONS
ALTER TABLE public.tuitions ENABLE ROW LEVEL SECURITY;

-- Policy 1: Authenticated teachers can view open tuitions; Admins can view all tuitions
DROP POLICY IF EXISTS "Authenticated users can view open tuitions" ON public.tuitions;
CREATE POLICY "Authenticated users can view open tuitions"
ON public.tuitions FOR SELECT
TO authenticated
USING (status = 'open' OR public.is_admin());

-- Policy 2: Only Admins can add tuitions
DROP POLICY IF EXISTS "Admins can insert tuitions" ON public.tuitions;
CREATE POLICY "Admins can insert tuitions"
ON public.tuitions FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

-- Policy 3: Only Admins can update tuitions (e.g. mark closed, edit details)
DROP POLICY IF EXISTS "Admins can update tuitions" ON public.tuitions;
CREATE POLICY "Admins can update tuitions"
ON public.tuitions FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Policy 4: Only Admins can delete tuitions
DROP POLICY IF EXISTS "Admins can delete tuitions" ON public.tuitions;
CREATE POLICY "Admins can delete tuitions"
ON public.tuitions FOR DELETE
TO authenticated
USING (public.is_admin());

-- 7. ENABLE REALTIME
-- Allows teachers to see new tuitions and status updates without refreshing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'tuitions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tuitions;
  END IF;
END $$;

-- 8. SAMPLE STARTER DATA (Optional)
INSERT INTO public.tuitions (tuition_number, status, subjects, class_name, area_city, details)
VALUES 
  ('1001', 'open', 'Mathematics, Physics', 'O Level / Grade 10', 'DHA Phase 5, Lahore', 'Looking for an experienced tutor for O Level Math (Syllabus D) & Physics. 4 days a week, 1.5 hours per day. Competitive stipend.'),
  ('1002', 'open', 'Chemistry, Biology', 'A Level / Year 12', 'F-7, Islamabad', 'Cambridge A Level Chemistry & Biology female tutor preferred. 3 days a week. Good compensation package.'),
  ('1003', 'open', 'English, Computer Science', 'IGCSE / Grade 9', 'Clifton, Karachi', 'Cambridge IGCSE curriculum. Focus on Python programming basics and English literature. Flexible timings in the evening.')
ON CONFLICT (tuition_number) DO NOTHING;

-- ==========================================================
-- HOW TO SET YOURSELF AS ADMIN:
-- After you log in with your Gmail for the first time, run this query:
--
-- UPDATE public.profiles
-- SET role = 'admin'
-- WHERE email = 'your_actual_gmail@gmail.com';
-- ==========================================================
