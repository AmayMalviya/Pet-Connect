-- Enable Row Level Security (RLS) on the animals_for_adoption table if it's not already enabled.
ALTER TABLE public.animals_for_adoption ENABLE ROW LEVEL SECURITY;

-- 1. Policy for INSERT
-- Allows a logged-in user to insert a new animal record for themselves.
-- The `WITH CHECK` clause ensures that the user_id of the new row must match the authenticated user's ID.
CREATE POLICY "Allow authenticated users to insert their own animals"
ON public.animals_for_adoption
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 2. Policy for SELECT
-- Allows any user (authenticated or anonymous) to view all animal records.
-- This is a permissive policy, which is common for public-facing data.
CREATE POLICY "Allow anyone to select all animals"
ON public.animals_for_adoption
FOR SELECT
TO public
USING (true);

-- 3. Policy for UPDATE
-- Allows a user to update an animal record, but only if they are the owner.
-- The `USING` clause specifies which rows the policy applies to.
CREATE POLICY "Allow owners to update their own animals"
ON public.animals_for_adoption
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Policy for DELETE
-- Allows a user to delete an animal record, but only if they are the owner.
CREATE POLICY "Allow owners to delete their own animals"
ON public.animals_for_adoption
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
