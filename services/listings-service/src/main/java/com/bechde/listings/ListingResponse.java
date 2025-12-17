package com.bechde.listings;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
public record ListingResponse(
    UUID id, String title, String description, BigDecimal priceAmount, 
    String currency, String category, String city, BigDecimal lat, 
    BigDecimal lon, String status, String slug, Instant publishedAt
) {}
