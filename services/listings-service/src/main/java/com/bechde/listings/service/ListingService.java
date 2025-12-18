package com.bechde.listings.service;

import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.repo.ListingRepository;
import org.springframework.stereotype.Service;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class ListingService {

    private final ListingRepository repo;

    public ListingService(ListingRepository repo) {
        this.repo = repo;
    }

    public Listing create(ListingCreateDto dto) {
        Listing l = new Listing();
        l.setTitle(dto.title());
        l.setDescription(dto.description());

        // Fix: Direct assignment (both are BigDecimal now)
        l.setPriceAmount(dto.priceAmount());

        // Fix: Use .currency() from record, not .priceCurrency()
        l.setCurrency(dto.currency());

        l.setCategory(dto.category());
        l.setCity(dto.city());
        l.setLat(dto.lat());
        l.setLon(dto.lon());

        // Defaults
        l.setStatus("ACTIVE");
        l.setPublishedAt(OffsetDateTime.now());
        l.setSlug(dto.title().toLowerCase().replace(" ", "-"));

        return repo.save(l);
    }
}
