#!/usr/bin/env bash

# Script: fix_all_listings_v2.sh
# Purpose: Fix listings-service schema drift, remove rogue files, align JPA mapping (DB-side fix), and rebuild.

set -euo pipefail

echo "== Bechde: Fix listings-service =="

# 0) Sanity Check
if [ ! -d "services/listings-service" ]; then
    echo "❌ Error: Run this from the repository root (missing services/listings-service)."
    exit 1
fi

BASE="services/listings-service/src/main/java/com/bechde/listings"
DOMAIN="$BASE/domain"
APP="$BASE/ListingsApplication.java"
ENTITY="$DOMAIN/Listing.java"
MIG_DIR="services/listings-service/src/main/resources/db/migration"
APP_YML="services/listings-service/src/main/resources/application.yml"

# 1) Remove rogue files that cause duplicate beans/entities
echo "-> Removing rogue files (if present)..."
declare -a RogueList=(
    "$BASE/Listing.java"
    "$BASE/ListingService.java"
    "$BASE/ListingController.java"
    "$BASE/ListingRepository.java"
)

for f in "${RogueList[@]}"; do
    if [ -f "$f" ]; then
        echo "   🗑️  Deleting $f"
        rm -f "$f"
    fi
done

# 2) Canonical Listing entity with explicit column names
echo "-> Writing canonical entity Listing.java..."
mkdir -p "$DOMAIN"
cat > "$ENTITY" <<'EOF'
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
EOF

# 3) Enforce correct scan packages (Corrected AWK Syntax)
echo "-> Ensuring scan packages on ListingsApplication..."
if [ -f "$APP" ]; then
    if ! grep -q "EntityScan" "$APP"; then
        awk '
        BEGIN{done=0}
        /@SpringBootApplication/ && !done {
            print "@org.springframework.boot.autoconfigure.SpringBootApplication(scanBasePackages = \"com.bechde.listings\")";
            print "@org.springframework.boot.autoconfigure.domain.EntityScan(basePackages = \"com.bechde.listings.domain\")";
            print "@org.springframework.data.jpa.repository.config.EnableJpaRepositories(basePackages = \"com.bechde.listings.repo\")";
            done=1;
            next
        }
        { print }
        ' "$APP" > "$APP.tmp" && mv "$APP.tmp" "$APP"
    fi
fi

# 4) Add Flyway migration to alter DB column type (Fixes mismatch)
echo "-> Adding V3 migration to fix numeric vs double mismatch..."
mkdir -p "$MIG_DIR"
V3="$MIG_DIR/V3__alter_price_amount_to_double_precision.sql"

if [ ! -f "$V3" ]; then
    cat > "$V3" <<'SQL'
-- Align price_amount to match JPA double (float(53))
ALTER TABLE listings ALTER COLUMN price_amount TYPE double precision USING price_amount::double precision;
SQL
    echo "   ✅ Created V3 migration."
else
    echo "   ℹ️  V3 migration already exists."
fi

# 5) Ensure application.yml is normalized
echo "-> Normalizing application.yml..."
cat > "$APP_YML" <<'EOF'
spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/bechde}
    username: ${DB_USER:bechde}
    password: ${DB_PASS:bechde}
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate.default_schema: listings
  flyway:
    enabled: true
    create-schemas: true
    schemas: listings
server:
  port: ${PORT:8081}
management:
  endpoints:
    web:
      exposure:
        include: health,info
EOF

# 6) Rebuild listings-service
echo "-> Building listings-service..."
# Note: Using clean compile to ensure no stale classes
( cd services/listings-service && ../../mvnw -B -q clean compile )

echo "✅ Fix applied."
echo "👉 Now run: bash run_all_local.sh"
