package com.bechde.listings.dto;
import jakarta.validation.constraints.*;
public record ListingCreateDto(
    @Size(min=10, max=120) String title,
    @Size(min=20, max=5000) String description,
    @PositiveOrZero double priceAmount,
    @Pattern(regexp="USD|INR|EUR") String priceCurrency,
    @Pattern(regexp="electronics|furniture|vehicles|other") String category,
    @Size(min=2, max=80) String city,
    Double lat,
    Double lon
) {}
