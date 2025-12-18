#!/usr/bin/env bash

# Script: fix_local_builds.sh
# Description: Fixes multiple main classes, updates Flyway for PG 15+, and standardizes POMs.
# Usage: bash scripts/fix_local_builds.sh

set -euo pipefail

echo "🔧 Bechde: Fixing local build environment..."

# 1. Ensure Maven Wrapper exists
if [ ! -f mvnw ]; then
    echo "📦 Generating Maven Wrapper (3.9.9)..."
    mvn -N -q wrapper:wrapper -Dmaven=3.9.9
    chmod +x mvnw
fi

# 2. Helper Function to Rewrite POMs
rewrite_pom() {
    local pom="$1"
    local artifact="$2"
    local deps="$3"
    local main_class="$4"

    echo "   -> Patching $artifact POM (Java 17, Flyway 10.20.0)..."
    cat > "$pom" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.2</version>
        <relativePath/>
    </parent>

    <groupId>com.bechde</groupId>
    <artifactId>${artifact}</artifactId>
    <version>0.1.0</version>

    <properties>
        <java.version>17</java.version>
        <flyway.version>10.20.0</flyway.version>
    </properties>

    <dependencies>
        ${deps}
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <release>17</release>
                    <encoding>UTF-8</encoding>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <mainClass>${main_class}</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
}

# --- Dependencies Definitions ---
DEPS_COMMON='
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>'

DEPS_JPA_PG='
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
    <dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>
    <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-core</artifactId><version>${flyway.version}</version></dependency>'

DEPS_JWT='
    <dependency><groupId>org.springframework.security</groupId><artifactId>spring-security-crypto</artifactId></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>0.11.5</version></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>0.11.5</version><scope>runtime</scope></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>0.11.5</version><scope>runtime</scope></dependency>'

# 3. Apply Fixes

# Listings Service: Fixes "Unable to find a single main class"
if [ -d services/listings-service ]; then
    rewrite_pom "services/listings-service/pom.xml" "listings-service" \
        "${DEPS_COMMON} ${DEPS_JPA_PG} <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>" \
        "com.bechde.listings.ListingsApplication"

    # Remove duplicate main class if exists
    DUP_MAIN="services/listings-service/src/main/java/com/bechde/listings/BechdeListingsApplication.java"
    if [ -f "$DUP_MAIN" ]; then
        echo "   ❌ Removing duplicate main class: $DUP_MAIN"
        rm "$DUP_MAIN"
    fi
fi

# Auth Service
if [ -d services/auth-service ]; then
    rewrite_pom "services/auth-service/pom.xml" "auth-service" \
        "${DEPS_COMMON} ${DEPS_JPA_PG} ${DEPS_JWT}" \
        "com.bechde.auth.AuthApplication"
fi

# Users Service
if [ -d services/users-service ]; then
    rewrite_pom "services/users-service/pom.xml" "users-service" \
        "${DEPS_COMMON} ${DEPS_JPA_PG} ${DEPS_JWT}" \
        "com.bechde.users.UsersApplication"
fi

# Payments Service
if [ -d services/payments-service ]; then
    rewrite_pom "services/payments-service/pom.xml" "payments-service" \
        "${DEPS_COMMON} <dependency><groupId>com.stripe</groupId><artifactId>stripe-java</artifactId><version>24.0.0</version></dependency>" \
        "com.bechde.payments.PaymentsApplication"
fi

# Media Service
if [ -d services/media-service ]; then
    rewrite_pom "services/media-service/pom.xml" "media-service" \
        "${DEPS_COMMON} <dependency><groupId>com.azure</groupId><artifactId>azure-storage-blob</artifactId><version>12.27.0</version></dependency>" \
        "com.bechde.media.MediaApplication"
fi

# Chat Service
if [ -d services/chat-service ]; then
    rewrite_pom "services/chat-service/pom.xml" "chat-service" \
        "${DEPS_COMMON} <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-mongodb</artifactId></dependency>" \
        "com.bechde.chat.ChatApplication"
fi

# API Gateway
if [ -d services/api-gateway ]; then
    echo "   -> Patching API Gateway POM..."
    cat > services/api-gateway/pom.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.2</version>
        <relativePath/>
    </parent>
    <groupId>com.bechde</groupId>
    <artifactId>api-gateway</artifactId>
    <version>0.1.0</version>
    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.3</spring-cloud.version>
    </properties>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>\${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    <dependencies>
        <dependency><groupId>org.springframework.cloud</groupId><artifactId>spring-cloud-starter-gateway</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId><configuration><mainClass>com.bechde.gateway.GatewayApplication</mainClass></configuration></plugin>
        </plugins>
    </build>
</project>
EOF
fi

# 4. Enforce ddl-auto: validate (Safety check)
echo "🛡️  Enforcing ddl-auto: validate in YAMLs..."
patch_validate() {
    local yml="$1"
    if [ -f "$yml" ]; then
        if grep -q 'ddl-auto' "$yml"; then
            # Safe replacement for Mac/Linux
             sed "s/ddl-auto:.*create.*/ddl-auto: validate/g" "$yml" > "$yml.tmp" && mv "$yml.tmp" "$yml"
             sed "s/ddl-auto:.*update.*/ddl-auto: validate/g" "$yml" > "$yml.tmp" && mv "$yml.tmp" "$yml"
        else
            printf "\nspring:\n  jpa:\n    hibernate:\n      ddl-auto: validate\n" >> "$yml"
        fi
    fi
}
patch_validate services/listings-service/src/main/resources/application.yml
patch_validate services/auth-service/src/main/resources/application.yml
patch_validate services/users-service/src/main/resources/application.yml

# 5. Build Verification
echo "🏗️  Verifying Builds (This may take a moment)..."
for svc in services/*; do
    if [ -d "$svc" ] && [ -f "$svc/pom.xml" ]; then
        echo "   🔹 Building $(basename "$svc")..."
        (cd "$svc" && ../../mvnw -B -q clean compile) || { echo "❌ Build failed for $svc"; exit 1; }
    fi
done

echo "✅ All fixes applied and builds succeeded!"
echo "👉 You can now run 'bash run_all_local.sh' safely."
