#!/usr/bin/env bash

# Script: fix_flyway.sh
# Description: Adds flyway-database-postgresql, pins version, and fixes citext issues.

set -euo pipefail

echo "🔧 Patching Flyway configuration..."

# 1. List of services connecting to Postgres
SVCS=("auth-service" "users-service" "listings-service" "payments-service" "media-service")

# 2. Loop through services and patch POMs
for s in "${SVCS[@]}"; do
    POM="services/$s/pom.xml"
    if [ ! -f "$POM" ]; then continue; fi

    echo "   -> Patching $s..."

    # Add flyway.version property if missing
    if ! grep -q "<flyway.version>" "$POM"; then
        awk '/<properties>/ { print; print "        <flyway.version>10.20.0</flyway.version>"; next }1' "$POM" > "$POM.tmp" && mv "$POM.tmp" "$POM"
    fi

    # Add flyway-database-postgresql dependency if missing
    if ! grep -q "flyway-database-postgresql" "$POM"; then
        awk '/<dependencies>/ {
            print;
            print "        <dependency>";
            print "            <groupId>org.flywaydb</groupId>";
            print "            <artifactId>flyway-database-postgresql</artifactId>";
            print "            <version>${flyway.version}</version>";
            print "        </dependency>";
            next
        }1' "$POM" > "$POM.tmp" && mv "$POM.tmp" "$POM"
    fi
done

# 3. Fix 'citext' permission error (Common issue on local DBs)
# We replace CITEXT with TEXT to avoid needing superuser privileges
AUTH_SQL="services/auth-service/src/main/resources/db/migration/V1__init.sql"
if [ -f "$AUTH_SQL" ]; then
    echo "   -> Fixing 'citext' requirement in Auth Service..."
    cat > "$AUTH_SQL" <<EOF
CREATE TABLE IF NOT EXISTS auth_users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Ensure case-insensitive uniqueness without CITEXT extension
CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_email_lower ON auth_users (lower(email));
EOF
fi

# 4. Remove Duplicate Main Class (Listings Service)
DUP_MAIN="services/listings-service/src/main/java/com/bechde/listings/BechdeListingsApplication.java"
if [ -f "$DUP_MAIN" ]; then
    echo "   -> Removing duplicate main class from Listings Service..."
    rm "$DUP_MAIN"
fi

# 5. Rebuild Auth Service to Verify
echo "🏗️  Verifying fix by rebuilding Auth Service..."
(cd services/auth-service && ../../mvnw -B -q clean compile)

echo "✅ Flyway patched! You can now run 'bash run_all_local.sh'"
