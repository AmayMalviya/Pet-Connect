-- Create the get_recommended_products function
CREATE OR REPLACE FUNCTION get_recommended_products(pet_id uuid)
RETURNS TABLE(
    id uuid,
    name text,
    category text,
    price numeric,
    image_url text,
    tags text[],
    reason text
)
LANGUAGE plpgsql
AS $$
DECLARE
    p_species text;
    p_breed text;
    p_allergies text[];
    p_medical_conditions text[];
BEGIN
    -- Fetch pet details
    SELECT
        species,
        breed,
        allergies,
        medical_conditions
    INTO
        p_species,
        p_breed,
        p_allergies,
        p_medical_conditions
    FROM pets
    WHERE id = pet_id;

    -- Return recommended products
    RETURN QUERY
    SELECT
        pp.id,
        pp.name,
        pp.category,
        pp.price,
        pp.image_url,
        pp.tags,
        CASE
            WHEN pp.species = p_species AND (pp.allowed_breeds IS NULL OR p_breed = ANY(pp.allowed_breeds)) THEN 'Tailored for ' || p_breed || ' ' || p_species
            WHEN pp.species = p_species THEN 'General for ' || p_species
            ELSE 'General product'
        END AS reason
    FROM pet_products pp
    WHERE
        pp.species = p_species
        AND (pp.allowed_breeds IS NULL OR p_breed = ANY(pp.allowed_breeds))
        AND NOT (pp.ingredients && p_allergies) -- Exclude products with ingredients the pet is allergic to
        AND NOT (pp.contraindications && p_medical_conditions); -- Exclude products conflicting with medical conditions
END;
$$;

-- Grant usage to authenticated users
GRANT EXECUTE ON FUNCTION get_recommended_products(uuid) TO authenticated;
