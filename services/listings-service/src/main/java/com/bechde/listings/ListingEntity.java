package com.bechde.listings;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name="listings")
public class ListingEntity {
    @Id
    private UUID id;
    @Column(nullable=false)
    private UUID userId;
    @Column(nullable=false, length=120)
    private String title;
    @Column(nullable=false, length=5000)
    private String description;
    @Column(nullable=false, precision=12, scale=2)
    private BigDecimal priceAmount;
    @Column(nullable=false, length=3)
    private String currency;
    @Column(nullable=false)
    private String category;
    @Column(nullable=false)
    private String city;
    private BigDecimal lat;
    private BigDecimal lon;
    @Column(nullable=false)
    private String status;
    @Column(nullable=false, unique=true)
    private String slug;
    @Column(nullable=false)
    private Instant createdAt;
    @Column(nullable=false)
    private Instant updatedAt;
    private Instant publishedAt;

    public UUID getId(){return id;}
    public void setId(UUID v){id=v;}
    public UUID getUserId(){return userId;}
    public void setUserId(UUID v){userId=v;}
    public String getTitle(){return title;}
    public void setTitle(String v){title=v;}
    public String getDescription(){return description;}
    public void setDescription(String v){description=v;}
    public BigDecimal getPriceAmount(){return priceAmount;}
    public void setPriceAmount(BigDecimal v){priceAmount=v;}
    public String getCurrency(){return currency;}
    public void setCurrency(String v){currency=v;}
    public String getCategory(){return category;}
    public void setCategory(String v){category=v;}
    public String getCity(){return city;}
    public void setCity(String v){city=v;}
    public BigDecimal getLat(){return lat;}
    public void setLat(BigDecimal v){lat=v;}
    public BigDecimal getLon(){return lon;}
    public void setLon(BigDecimal v){lon=v;}
    public String getStatus(){return status;}
    public void setStatus(String v){status=v;}
    public String getSlug(){return slug;}
    public void setSlug(String v){slug=v;}
    public Instant getCreatedAt(){return createdAt;}
    public void setCreatedAt(Instant v){createdAt=v;}
    public Instant getUpdatedAt(){return updatedAt;}
    public void setUpdatedAt(Instant v){updatedAt=v;}
    public Instant getPublishedAt(){return publishedAt;}
    public void setPublishedAt(Instant v){publishedAt=v;}
}
