package com.bechde.listings;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/listings")
public class ListingController {
    private final ListingService service;
    public ListingController(ListingService service){ this.service=service; }

    @PostMapping
    public ResponseEntity<ListingResponse> create(@Valid @RequestBody ListingCreateRequest req) {
        UUID userId = UUID.randomUUID(); // TODO: JWT
        var saved = service.create(userId, req);
        var resp = new ListingResponse(
            saved.getId(), saved.getTitle(), saved.getDescription(), saved.getPriceAmount(),
            saved.getCurrency(), saved.getCategory(), saved.getCity(), saved.getLat(),
            saved.getLon(), saved.getStatus(), saved.getSlug(), saved.getPublishedAt()
        );
        return ResponseEntity.created(URI.create("/listings/"+saved.getId())).body(resp);
    }
}
