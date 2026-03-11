-- ============================================================================
-- Supabase SQL Migration: Admin Features Setup
-- ============================================================================
-- This script sets up all necessary database columns and structures for:
-- 1. KYC verification tracking
-- 2. User ban/block functionality
-- 3. Admin profile management
--
-- Run this directly in your Supabase SQL Editor
-- ============================================================================

-- 1. Add is_banned column to profiles table (if not exists)
-- This allows admins to temporarily ban/block users
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;

-- Add comment for clarity
COMMENT ON COLUMN profiles.is_banned IS 'Flag to indicate if user is banned/blocked by admin';

-- ============================================================================
-- 2. Ensure kyc_verified column exists in profiles table
-- This tracks whether a user has completed KYC and been approved by admin
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS kyc_verified BOOLEAN DEFAULT false;

COMMENT ON COLUMN profiles.kyc_verified IS 'Flag indicating if user KYC has been verified by admin';

-- ============================================================================
-- 3. Verify kyc_documents table structure
-- If the table doesn't exist, create it with proper schema
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_photo_url TEXT,
  selfie_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON kyc_documents(status);

-- Add comment
COMMENT ON TABLE kyc_documents IS 'Stores KYC document submission (ID photo, selfie)';

-- ============================================================================
-- 4. Verify kyc_personal table structure
-- Stores personal verification details (phone verification, OTP, etc.)
CREATE TABLE IF NOT EXISTS kyc_personal (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  is_otp_verified BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'unverified' CHECK (status IN ('unverified', 'pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_kyc_personal_user_id ON kyc_personal(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_personal_status ON kyc_personal(status);

-- Add comment
COMMENT ON TABLE kyc_personal IS 'Stores personal KYC verification details (name, phone, OTP status)';

-- ============================================================================
-- 5. Normalize existing role values from 'Shelter Owner' to 'Shelter'
-- This ensures consistency with the new canonical role names
UPDATE profiles
SET role = 'Shelter'
WHERE role = 'Shelter Owner';

-- ============================================================================
-- 6. Set default values for any NULL kyc_verified or is_banned
UPDATE profiles SET kyc_verified = false WHERE kyc_verified IS NULL;
UPDATE profiles SET is_banned = false WHERE is_banned IS NULL;

-- ============================================================================
-- 7. Create an index on profiles for faster filtering (admin dashboard)
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_verified ON profiles(kyc_verified);
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON profiles(is_banned);

-- ============================================================================
-- 8. Enable RLS (Row Level Security) on kyc tables if needed
-- Uncomment these if you want to enforce RLS policies
-- ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE kyc_personal ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own KYC data
-- CREATE POLICY "Users can view own KYC documents" ON kyc_documents
--   FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- CREATE POLICY "Users can view own KYC personal" ON kyc_personal
--   FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- ============================================================================
-- 9. Verify profiles table structure for admin needs
-- Make sure all necessary columns exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS capacity TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS experience TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ============================================================================
-- 10. Create view for admin dashboard to see pending KYC requests
CREATE OR REPLACE VIEW admin_pending_kyc_requests AS
SELECT
  p.user_id,
  p.first_name,
  p.last_name,
  p.email,
  p.phone,
  p.role,
  p.city,
  p.state,
  p.country,
  p.kyc_verified,
  p.is_banned,
  kd.id as kyc_doc_id,
  kd.id_photo_url,
  kd.selfie_url,
  kd.status as doc_status,
  kd.created_at as doc_submitted_at,
  kp.id as kyc_personal_id,
  kp.full_name as personal_full_name,
  kp.phone as personal_phone,
  kp.is_otp_verified,
  kp.status as personal_status,
  kp.created_at as personal_submitted_at
FROM profiles p
LEFT JOIN kyc_documents kd ON p.user_id = kd.user_id
LEFT JOIN kyc_personal kp ON p.user_id = kp.user_id
WHERE p.kyc_verified = false AND (p.role = 'Shelter' OR p.role = 'Shelter Owner')
ORDER BY COALESCE(kd.created_at, kp.created_at, p.created_at) DESC;

COMMENT ON VIEW admin_pending_kyc_requests IS 'View for admins to see all pending KYC verification requests with full details';

-- ============================================================================
-- 11. Create view for admin dashboard to see all banned users
CREATE OR REPLACE VIEW admin_banned_users AS
SELECT
  user_id,
  first_name,
  last_name,
  email,
  phone,
  role,
  city,
  state,
  country,
  is_banned,
  created_at
FROM profiles
WHERE is_banned = true
ORDER BY created_at DESC;

COMMENT ON VIEW admin_banned_users IS 'View for admins to see all banned/blocked users';

-- ============================================================================
-- 12. Create view for admin dashboard to see all profiles by role
CREATE OR REPLACE VIEW admin_all_profiles_by_role AS
SELECT
  user_id,
  first_name,
  last_name,
  email,
  phone,
  role,
  city,
  state,
  country,
  kyc_verified,
  is_banned,
  created_at
FROM profiles
ORDER BY role ASC, created_at DESC;

COMMENT ON VIEW admin_all_profiles_by_role IS 'View for admins to manage all profiles filtered by role';

-- ============================================================================
-- Done! Summary of changes:
-- ============================================================================
-- ✅ Added is_banned column to profiles (for admin ban/block feature)
-- ✅ Added kyc_verified column to profiles (for KYC approval tracking)
-- ✅ Created/verified kyc_documents table (for document submissions)
-- ✅ Created/verified kyc_personal table (for personal verification)
-- ✅ Normalized 'Shelter Owner' role values to 'Shelter'
-- ✅ Added indexes for performance
-- ✅ Created admin dashboard views for KYC and user management
--
-- You can now use these in your Flutter app:
-- 1. Toggle admin.is_banned to ban/unban users
-- 2. Update profiles.kyc_verified when admin approves KYC
-- 3. Query kyc_documents and kyc_personal for full KYC details
-- 4. Use the admin_pending_kyc_requests view to show pending requests
-- ============================================================================
