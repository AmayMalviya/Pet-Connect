DROP FUNCTION IF EXISTS get_recommended_products(uuid);

create or replace function get_recommended_products(p_pet_id uuid)
returns json
language plpgsql
as $$
begin
  return (
    select json_agg(
      json_build_object(
        'id', p.id,
        'name', p.name,
        'category', p.category,
        'price', p.price,
        'image_url', p.image_url,
        'tags', p.tags,
        'reason',
        case
          when p.breeds_allowed is not null and pt.breed = any(p.breeds_allowed) then 'Recommended for ' || pt.breed
          when p.allergy_warning is not null and not (p.allergy_warning && pt.allergies) then 'Good for pets with allergies'
          when p.medical_restriction is not null and not (p.medical_restriction && pt.medical_conditions) then 'Good for pets with ' || array_to_string(pt.medical_conditions, ', ')
          when d.common_food_allergies is not null and not (p.allergy_warning && string_to_array(d.common_food_allergies, ', ')) then 'Good for ' || pt.breed || ' breed'
          when c.common_food_allergies is not null and not (p.allergy_warning && string_to_array(c.common_food_allergies, ', ')) then 'Good for ' || pt.breed || ' breed'
          else 'Generally recommended'
        end
      )
    )
    from pet_products p
    join pets pt on pt.id = p_pet_id
    left join dogs_pet_data d on pt.animal = 'Dog' and pt.breed_id = d.breed_id
    left join cats_pet_data c on pt.animal = 'Cat' and pt.breed_id = c.breed_id
    where p.species = pt.animal
      and (p.breeds_allowed is null or pt.breed = any(p.breeds_allowed))
      and (p.allergy_warning is null or not (p.allergy_warning && pt.allergies))
      and (p.medical_restriction is null or not (p.medical_restriction && pt.medical_conditions))
      and (d.common_food_allergies is null or p.allergy_warning is null or not (p.allergy_warning && string_to_array(d.common_food_allergies, ', ')))
      and (c.common_food_allergies is null or p.allergy_warning is null or not (p.allergy_warning && string_to_array(c.common_food_allergies, ', ')))
  );
end; $$;