INSERT INTO pet_products (name, category, price, image_url, product_url, source, species, breeds_allowed, allergy_warning, medical_restriction, ingredients, tags)
VALUES
  ('Premium Dog Food', 'Food', '45.99', 'https://example.com/dog_food.jpg', 'https://shop.com/dog-food', 'seed',
    'dog', NULL, ARRAY['chicken','rice'], NULL, ARRAY['chicken','rice'], ARRAY['high-protein','grain-free']),
  ('Small Breed Dog Food', 'Food', '30.00', 'https://example.com/small_dog_food.jpg', 'https://shop.com/small-dog-food', 'seed',
    'dog', NULL, ARRAY['beef'], NULL, ARRAY['beef'], ARRAY['small-breed']),
  ('Hypoallergenic Dog Shampoo', 'Grooming', '15.00', 'https://example.com/dog_shampoo.jpg', 'https://shop.com/dog-shampoo', 'seed',
    'dog', NULL, NULL, ARRAY['skin-allergies'], NULL, ARRAY['sensitive-skin']),
  ('Indoor Cat Food', 'Food', '35.00', 'https://example.com/indoor_cat_food.jpg', 'https://shop.com/indoor-cat-food', 'seed',
    'cat', NULL, ARRAY['fish'], NULL, ARRAY['fish'], ARRAY['indoor','hairball-control']),
  ('Interactive Cat Laser Toy', 'Toys', '12.50', 'https://example.com/cat_laser.jpg', 'https://shop.com/cat-laser', 'seed',
    'cat', NULL, NULL, NULL, NULL, ARRAY['exercise'])
ON CONFLICT DO NOTHING;