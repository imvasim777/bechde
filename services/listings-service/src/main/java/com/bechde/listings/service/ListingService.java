package com.bechde.listings.service;
import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.repo.ListingRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Service
public class ListingService {
    private final ListingRepository repo;
    public ListingService(ListingRepository repo) { this.repo = repo; }
    @Transactional
    public Listing create(ListingCreateDto dto) {
        Listing l = new Listing();
        l.setTitle(dto.title());
        l.setDescription(dto.description());
        l.setPriceAmount(dto.priceAmount());
        l.setPriceCurrency(dto.priceCurrency());
        l.setCategory(dto.category());
        l.setCity(dto.city());
        l.setLat(dto.lat());
        l.setLon(dto.lon());
        l.setSlug(slugify(dto.title()));
        return repo.save(l);
    }
    private String slugify(String s) {
        return s == null ? null : s.toLowerCase().replaceAll("[^a-z0-9]+", "-").replaceAll("(^-|-$)", "");
    }
}
