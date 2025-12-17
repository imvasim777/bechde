package com.bechde.listings;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record ListingCreateRequest(
    @NotBlank @Size(min=10,max=120) String title,
    @NotBlank @Size(min=20,max=5000) String description,
    Money price,
    @NotBlank String category,
    @NotBlank @Size(min=2,max=80) String city,
    BigDecimal lat,
    BigDecimal lon
) {
    public static record Money(
        @NotNull @DecimalMin("0.0") BigDecimal amount,
        @NotBlank @Pattern(regexp="USD|INR|EUR") String currency
    ) {}
}
