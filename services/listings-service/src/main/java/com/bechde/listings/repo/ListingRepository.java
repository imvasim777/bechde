package com.bechde.listings.repo;
import com.bechde.listings.domain.Listing;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface ListingRepository extends JpaRepository<Listing, UUID> {}
