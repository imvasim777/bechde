package com.bechde.listings.web;
import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.service.ListingService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/listings")
public class ListingsController {
    private final ListingService svc;
    public ListingsController(ListingService svc) { this.svc = svc; }
    @PostMapping
    public ResponseEntity<Listing> create(@Valid @RequestBody ListingCreateDto dto) {
        Listing saved = svc.create(dto);
        return ResponseEntity.created(java.net.URI.create("/listings/" + saved.getId())).body(saved);
    }
}
