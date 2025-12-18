package com.bechde.listings.web;

import com.bechde.listings.domain.Listing;
import com.bechde.listings.ListingResponse;

class ListingResponseMapper {
    static ListingResponse toDto(Listing l) {
        return new ListingResponse(
            l.getId(),
            l.getTitle(),
            l.getDescription(),
            l.getPriceAmount(),
            l.getCurrency(),
            l.getCategory(),
            l.getCity(),
            l.getLat(),
            l.getLon(),
            // Fix: l.getStatus() is a String, so we don't need .name()
            l.getStatus(),
            l.getSlug(),
            l.getPublishedAt()
        );
    }
}
