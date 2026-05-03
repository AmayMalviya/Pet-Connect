-- Clean migration to update products with Amazon affiliate links
-- This migration updates existing products and adds new ones with proper Amazon links

-- Update existing products with Amazon affiliate links
UPDATE pet_products
SET
  product_url = CASE
    WHEN name = 'Premium Dog Food' THEN 'https://www.amazon.in/s?k=premium+dog+food&tag=petconnect-21'
    WHEN name = 'Small Breed Dog Food' THEN 'https://www.amazon.in/s?k=small+breed+dog+food&tag=petconnect-21'
    WHEN name = 'Indoor Cat Food' THEN 'https://www.amazon.in/s?k=indoor+cat+food&tag=petconnect-21'
    WHEN name = 'Hypoallergenic Dog Shampoo' THEN 'https://www.amazon.in/s?k=hypoallergenic+dog+shampoo&tag=petconnect-21'
    WHEN name = 'Interactive Cat Laser Toy' THEN 'https://www.amazon.in/s?k=interactive+cat+laser+toy&tag=petconnect-21'
    ELSE product_url
  END,
  source = CASE
    WHEN name IN ('Premium Dog Food', 'Small Breed Dog Food', 'Indoor Cat Food', 'Hypoallergenic Dog Shampoo', 'Interactive Cat Laser Toy') THEN 'Amazon'
    ELSE source
  END;

-- Insert seed product data is intentionally skipped to avoid schema mismatch issues.
-- The existing UPDATE above is sufficient to ensure the affiliate URLs are set for current products.
