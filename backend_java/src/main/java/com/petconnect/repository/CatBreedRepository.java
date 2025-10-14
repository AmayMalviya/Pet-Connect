package com.petconnect.repository;

import com.petconnect.model.CatBreed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CatBreedRepository extends JpaRepository<CatBreed, Integer> {
}
