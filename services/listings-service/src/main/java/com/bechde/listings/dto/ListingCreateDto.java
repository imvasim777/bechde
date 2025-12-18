package com.bechde.listings.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record ListingCreateDto(
    @NotBlank @Size(min=10, max=120) String title,
    @NotBlank @Size(min=20, max=5000) String description,
    @NotNull @DecimalMin("0.0") BigDecimal priceAmount,
    @NotBlank String currency,
    @NotBlank String category,
    @NotBlank String city,
    Double lat,
    Double lon
) {}
