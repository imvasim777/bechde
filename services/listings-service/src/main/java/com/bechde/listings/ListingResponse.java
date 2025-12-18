package com.bechde.listings;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record ListingResponse(
    UUID id,
    String title,
    String description,
    BigDecimal priceAmount,
    String currency,
    String category,
    String city,
    Double lat,
    Double lon,
    String status,
    String slug,
    OffsetDateTime publishedAt
) {}
