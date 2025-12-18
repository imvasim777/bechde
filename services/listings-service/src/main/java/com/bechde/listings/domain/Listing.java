package com.bechde.listings.domain;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "listings")
public class Listing {

    @Id
    private UUID id = UUID.randomUUID();

    private String title;

    @Column(length = 5000, nullable = false)
    private String description;

    @Column(name = "price_amount", nullable = false)
    private double priceAmount;

    @Column(name = "price_currency", length = 3, nullable = false)
    private String priceCurrency;

    private String category;
    private String city;
    private Double lat;
    private Double lon;

    private String status = "draft";
    private String slug;

    private OffsetDateTime publishedAt;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    // -- Getters and Setters --
    public java.util.UUID getId(){return id;}
    public void setId(java.util.UUID v){this.id=v;}
    public String getTitle(){return title;}
    public void setTitle(String v){this.title=v;}
    public String getDescription(){return description;}
    public void setDescription(String v){this.description=v;}
    public double getPriceAmount(){return priceAmount;}
    public void setPriceAmount(double v){this.priceAmount=v;}
    public String getPriceCurrency(){return priceCurrency;}
    public void setPriceCurrency(String v){this.priceCurrency=v;}
    public String getCategory(){return category;}
    public void setCategory(String v){this.category=v;}
    public String getCity(){return city;}
    public void setCity(String v){this.city=v;}
    public Double getLat(){return lat;}
    public void setLat(Double v){this.lat=v;}
    public Double getLon(){return lon;}
    public void setLon(Double v){this.lon=v;}
    public String getStatus(){return status;}
    public void setStatus(String v){this.status=v;}
    public String getSlug(){return slug;}
    public void setSlug(String v){this.slug=v;}
    public OffsetDateTime getPublishedAt(){return publishedAt;}
    public void setPublishedAt(OffsetDateTime v){this.publishedAt=v;}
    public OffsetDateTime getCreatedAt(){return createdAt;}
    public void setCreatedAt(OffsetDateTime v){this.createdAt=v;}
    public OffsetDateTime getUpdatedAt(){return updatedAt;}
    public void setUpdatedAt(OffsetDateTime v){this.updatedAt=v;}
}
