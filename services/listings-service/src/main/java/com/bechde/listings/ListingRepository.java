package com.bechde.listings;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface ListingRepository extends JpaRepository<ListingEntity, UUID> {
    boolean existsBySlug(String slug);
}
