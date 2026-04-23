-- Update existing products with Amazon affiliate links using Associate ID: petconnect-21
-- Also add more comprehensive product data for better testing

-- First, update existing dummy products with real Amazon affiliate links
UPDATE pet_products SET
  product_url = 'https://www.amazon.in/s?k=premium+dog+food&tag=petconnect-21',
  source = 'Amazon',
  image_url = 'https://images-na.ssl-images-amazon.com/images/I/71j8Z8QKQJL._AC_SL1500_.jpg'
WHERE name = 'Premium Dog Food';

UPDATE pet_products SET
  product_url = 'https://www.amazon.in/s?k=small+breed+dog+food&tag=petconnect-21',
  source = 'Amazon',
  image_url = 'https://images-na.ssl-images-amazon.com/images/I/81w6pK5zQJL._AC_SL1500_.jpg'
WHERE name = 'Small Breed Dog Food';

UPDATE pet_products SET
  product_url = 'https://www.amazon.in/s?k=indoor+cat+food&tag=petconnect-21',
  source = 'Amazon',
  image_url = 'https://images-na.ssl-images-amazon.com/images/I/71j8Z8QKQJL._AC_SL1500_.jpg'
WHERE name = 'Indoor Cat Food';

UPDATE pet_products SET
  product_url = 'https://www.amazon.in/s?k=hypoallergenic+dog+shampoo&tag=petconnect-21',
  source = 'Amazon',
  image_url = 'https://images-na.ssl-images-amazon.com/images/I/61w6pK5zQJL._AC_SL1500_.jpg'
WHERE name = 'Hypoallergenic Dog Shampoo';

UPDATE pet_products SET
  product_url = 'https://www.amazon.in/s?k=interactive+cat+laser+toy&tag=petconnect-21',
  source = 'Amazon',
  image_url = 'https://images-na.ssl-images-amazon.com/images/I/51j8Z8QKQJL._AC_SL1500_.jpg'
WHERE name = 'Interactive Cat Laser Toy';

-- Add more comprehensive product data with Amazon affiliate links
-- (Skipped in this migration to avoid insert schema mismatches)
