#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
BACKEND_DIR="services/listings-service"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Error: Backend directory not found. Run from repo root."
    exit 1
fi

echo "🔧 Configuring Backend for H2 In-Memory Mode..."
cd "$BACKEND_DIR"

# --- 1. Add H2 Dependency to pom.xml ---
echo "--- Step 1: Patching pom.xml ---"
if grep -q "com.h2database" pom.xml; then
    echo "   H2 dependency already present."
else
    # Insert H2 dependency safely before </dependencies>
    sed '/<\/dependencies>/i \
        <dependency>\
            <groupId>com.h2database</groupId>\
            <artifactId>h2</artifactId>\
            <scope>runtime</scope>\
        </dependency>' pom.xml > pom.xml.tmp && mv pom.xml.tmp pom.xml
    echo "   Added H2 dependency."
fi

# --- 2. Update application.yml (Disable Flyway) ---
echo "--- Step 2: Configuring application.yml ---"
# We overwrite the file to ensure a clean, working H2 config
cat > src/main/resources/application.yml <<EOF
server:
  port: 8081

spring:
  application:
    name: listings-service
  jackson:
    serialization:
      WRITE_DATES_AS_TIMESTAMPS: false
  datasource:
    url: jdbc:h2:mem:listingsdb
    driverClassName: org.h2.Driver
    username: sa
    password: password
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
    hibernate:
      ddl-auto: update
  flyway:
    enabled: false
EOF

echo "---------------------------------------------------"
echo "✅ Backend Configured for H2!"
echo "---------------------------------------------------"
echo "👉 Start the backend now:"
echo "   cd $BACKEND_DIR"
echo "   ./mvnw clean spring-boot:run -Dspring-boot.run.jvmArguments=\"-Dserver.port=8081\""
echo ""
echo "👉 Once started, verify with:"
echo "   curl -i \"http://localhost:8081/listings?page=0&size=10\""
echo "---------------------------------------------------"
