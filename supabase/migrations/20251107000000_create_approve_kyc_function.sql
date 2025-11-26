-- Step 1: Create a helper function to securely check if the currently authenticated user is an admin.
-- It does this by checking the 'role' column in the 'profiles' table.
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE user_id = auth.uid() AND (role = 'Admin' OR role = 'admin') -- Check for both 'Admin' and 'admin' roles
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create the main function to handle the KYC approval logic.
-- This can only be called by an authenticated user and will only execute if the user is an admin.
CREATE OR REPLACE FUNCTION approve_kyc(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- First, verify that the caller is an admin. If not, raise an exception.
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Permission denied: Only admins can approve KYC.';
  END IF;

  -- If the check passes, proceed with updating the user's status across all relevant tables.
  UPDATE public.profiles
  SET kyc_verified = TRUE
  WHERE user_id = target_user_id;

  UPDATE public.kyc_documents
  SET status = 'approved'
  WHERE user_id = target_user_id;

  UPDATE public.kyc_personal
  SET status = 'approved'
  WHERE user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
