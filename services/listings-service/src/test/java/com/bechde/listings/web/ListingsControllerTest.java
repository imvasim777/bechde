package com.bechde.listings.web;
import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.service.ListingService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import org.springframework.http.MediaType;
import com.fasterxml.jackson.databind.ObjectMapper;
@WebMvcTest(ListingsController.class)
class ListingsControllerTest {
    @Autowired MockMvc mvc;
    @MockBean ListingService svc;
    ObjectMapper om = new ObjectMapper();
    @Test
    void createListing_returns201() throws Exception {
        Listing l = new Listing();
        l.setTitle("Great Phone");
        Mockito.when(svc.create(Mockito.any(ListingCreateDto.class))).thenReturn(l);
        String json = """
            {"title":"Great Phone 2024","description":"Like new phone with all accessories","priceAmount":100,"priceCurrency":"USD","category":"electronics","city":"NYC"}
        """;
        mvc.perform(post("/listings").contentType(MediaType.APPLICATION_JSON).content(json))
           .andExpect(status().isCreated());
    }
}
