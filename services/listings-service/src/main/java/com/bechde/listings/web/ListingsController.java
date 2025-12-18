package com.bechde.listings.web;

import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.repo.ListingRepository;
import com.bechde.listings.service.ListingService;
import com.bechde.listings.ListingResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.net.URI;
import java.util.UUID;

@CrossOrigin(origins = "http://localhost:4200")
@RestController
@RequestMapping("/listings")
public class ListingsController {

    private final ListingService svc;
    private final ListingRepository repo;

    public ListingsController(ListingService svc, ListingRepository repo) {
        this.svc = svc;
        this.repo = repo;
    }

    @PostMapping
    public ResponseEntity<ListingResponse> create(@Valid @RequestBody ListingCreateDto dto) {
        Listing saved = svc.create(dto);
        return ResponseEntity
                .created(URI.create("/listings/" + saved.getId()))
                .body(ListingResponseMapper.toDto(saved));
    }

    @GetMapping
    public Page<ListingResponse> list(
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="10") int size) {

        Pageable pageable = PageRequest.of(
            Math.max(page, 0),
            Math.min(size, 50),
            Sort.by(Sort.Direction.DESC, "publishedAt")
        );

        return repo.findAll(pageable).map(ListingResponseMapper::toDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ListingResponse> get(@PathVariable UUID id) {
        return repo.findById(id)
                .map(ListingResponseMapper::toDto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
