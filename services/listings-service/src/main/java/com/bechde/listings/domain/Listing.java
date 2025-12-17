package com.bechde.listings.domain;
import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;
@Entity @Table(name="listings")
public class Listing {
    @Id private UUID id = UUID.randomUUID();
    private String title;
    @Column(length=5000) private String description;
    private double priceAmount;
    private String priceCurrency;
    private String category;
    private String city;
    private Double lat;
    private Double lon;
    private String status = "draft";
    private String slug;
    private OffsetDateTime publishedAt;
    private OffsetDateTime createdAt = OffsetDateTime.now();
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getId() { return id; }
    public String getTitle() { return title; }
    public void setTitle(String t) { this.title = t; }
    public String getDescription() { return description; }
    public void setDescription(String d) { this.description = d; }
    public double getPriceAmount() { return priceAmount; }
    public void setPriceAmount(double p) { this.priceAmount = p; }
    public String getPriceCurrency() { return priceCurrency; }
    public void setPriceCurrency(String c) { this.priceCurrency = c; }
    public String getCategory() { return category; }
    public void setCategory(String c) { this.category = c; }
    public String getCity() { return city; }
    public void setCity(String c) { this.city = c; }
    public Double getLat() { return lat; }
    public void setLat(Double v) { this.lat = v; }
    public Double getLon() { return lon; }
    public void setLon(Double v) { this.lon = v; }
    public String getStatus() { return status; }
    public void setStatus(String s) { this.status = s; }
    public String getSlug() { return slug; }
    public void setSlug(String s) { this.slug = s; }
    public OffsetDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(OffsetDateTime t) { this.publishedAt = t; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime t) { this.createdAt = t; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime t) { this.updatedAt = t; }
}
