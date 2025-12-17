package com.bechde.listings;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.UUID;

@Service
public class ListingService {
    private final ListingRepository repo;
    public ListingService(ListingRepository repo){ this.repo=repo; }

    @Transactional
    public ListingEntity create(UUID userId, ListingCreateRequest req) {
        var now = Instant.now();
        var e = new ListingEntity();
        e.setId(UUID.randomUUID());
        e.setUserId(userId);
        e.setTitle(req.title().trim());
        e.setDescription(req.description().trim());
        e.setPriceAmount(req.price().amount());
        e.setCurrency(req.price().currency());
        e.setCategory(req.category());
        e.setCity(req.city().trim());
        e.setLat(req.lat());
        e.setLon(req.lon());
        e.setStatus("draft");
        e.setSlug(generateUniqueSlug(req.title()));
        e.setCreatedAt(now);
        e.setUpdatedAt(now);
        return repo.save(e);
    }

    String generateUniqueSlug(String title) {
        var base = title.toLowerCase().replaceAll("[^a-z0-9]+","-").replaceAll("(^-|-$)","");
        var slug = base;
        int i=1;
        while (repo.existsBySlug(slug)) { slug = base + "-" + (++i); }
        return slug;
    }
}
