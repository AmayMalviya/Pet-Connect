package com.petconnect.model;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name = "cats_pet_data")
public class CatBreed {

    @Id
    private Integer breed_id;

    private String breed_name;
    private String size;
    private String weight_range;
    private String height_range;
    private String lifespan;
    private String origin_country;
    private String temperament;
    private String energy_level;
    private String diet;
    private String exercise_needs;
    private String living_environment;
    private String recommended_products;
    private String toiletry_needs;
    private String avg_monthly_cost;
    private String population_status;
    private String special_notes;
    private String image_url;
    private String source_url;
    private String field_sources;

    // Getters and Setters

    public Integer getBreed_id() {
        return breed_id;
    }

    public void setBreed_id(Integer breed_id) {
        this.breed_id = breed_id;
    }

    public String getBreed_name() {
        return breed_name;
    }

    public void setBreed_name(String breed_name) {
        this.breed_name = breed_name;
    }

    public String getSize() {
        return size;
    }

    public void setSize(String size) {
        this.size = size;
    }

    public String getWeight_range() {
        return weight_range;
    }

    public void setWeight_range(String weight_range) {
        this.weight_range = weight_range;
    }

    public String getHeight_range() {
        return height_range;
    }

    public void setHeight_range(String height_range) {
        this.height_range = height_range;
    }

    public String getLifespan() {
        return lifespan;
    }

    public void setLifespan(String lifespan) {
        this.lifespan = lifespan;
    }

    public String getOrigin_country() {
        return origin_country;
    }

    public void setOrigin_country(String origin_country) {
        this.origin_country = origin_country;
    }

    public String getTemperament() {
        return temperament;
    }

    public void setTemperament(String temperament) {
        this.temperament = temperament;
    }

    public String getEnergy_level() {
        return energy_level;
    }

    public void setEnergy_level(String energy_level) {
        this.energy_level = energy_level;
    }

    public String getDiet() {
        return diet;
    }

    public void setDiet(String diet) {
        this.diet = diet;
    }

    public String getExercise_needs() {
        return exercise_needs;
    }

    public void setExercise_needs(String exercise_needs) {
        this.exercise_needs = exercise_needs;
    }

    public String getLiving_environment() {
        return living_environment;
    }

    public void setLiving_environment(String living_environment) {
        this.living_environment = living_environment;
    }

    public String getRecommended_products() {
        return recommended_products;
    }

    public void setRecommended_products(String recommended_products) {
        this.recommended_products = recommended_products;
    }

    public String getToiletry_needs() {
        return toiletry_needs;
    }

    public void setToiletry_needs(String toiletry_needs) {
        this.toiletry_needs = toiletry_needs;
    }

    public String getAvg_monthly_cost() {
        return avg_monthly_cost;
    }

    public void setAvg_monthly_cost(String avg_monthly_cost) {
        this.avg_monthly_cost = avg_monthly_cost;
    }

    public String getPopulation_status() {
        return population_status;
    }

    public void setPopulation_status(String population_status) {
        this.population_status = population_status;
    }

    public String getSpecial_notes() {
        return special_notes;
    }

    public void setSpecial_notes(String special_notes) {
        this.special_notes = special_notes;
    }

    public String getImage_url() {
        return image_url;
    }

    public void setImage_url(String image_url) {
        this.image_url = image_url;
    }

    public String getSource_url() {
        return source_url;
    }

    public void setSource_url(String source_url) {
        this.source_url = source_url;
    }

    public String getField_sources() {
        return field_sources;
    }

    public void setField_sources(String field_sources) {
        this.field_sources = field_sources;
    }
}
