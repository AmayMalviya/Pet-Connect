-- Create product_clicks table for analytics
CREATE TABLE IF NOT EXISTS product_clicks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    clicked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_product_clicks_product_id ON product_clicks(product_id);
CREATE INDEX IF NOT EXISTS idx_product_clicks_user_id ON product_clicks(user_id);
CREATE INDEX IF NOT EXISTS idx_product_clicks_clicked_at ON product_clicks(clicked_at);

-- Enable RLS
ALTER TABLE product_clicks ENABLE ROW LEVEL SECURITY;

-- RLS policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'product_clicks'
      AND policyname = 'Users can insert their own clicks'
  ) THEN
    CREATE POLICY "Users can insert their own clicks" ON product_clicks
        FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'product_clicks'
      AND policyname = 'Users can view their own clicks'
  ) THEN
    CREATE POLICY "Users can view their own clicks" ON product_clicks
        FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'product_clicks'
      AND policyname = 'Admins can view all product clicks'
  ) THEN
    CREATE POLICY "Admins can view all product clicks" ON product_clicks
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM profiles
                WHERE profiles.user_id = auth.uid()
                AND profiles.role IN ('Admin', 'Super Admin')
            )
        );
  END IF;
END
$$;