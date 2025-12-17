#!/usr/bin/env bash

# Script: fix_project_structure.sh
# Description: Creates root POM, standardizes all service POMs to Java 17, and pushes fixes.
# Fixes: "MissingProjectException" by creating a root aggregator POM first.

set -euo pipefail

echo "🛠️  Fixing Bechde Project Structure..."

# 1. Create Root POM (Fixes Maven Error)
echo "   -> Creating root pom.xml..."
cat > pom.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.bechde</groupId>
    <artifactId>bechde-monorepo</artifactId>
    <version>0.1.0</version>
    <packaging>pom</packaging>

    <modules>
        <module>services/auth-service</module>
        <module>services/users-service</module>
        <module>services/listings-service</module>
        <module>services/payments-service</module>
        <module>services/media-service</module>
        <module>services/chat-service</module>
        <module>services/api-gateway</module>
    </modules>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
</project>
EOF

# 2. Generate Maven Wrapper (Now that POM exists)
if [ ! -f mvnw ]; then
    echo "📦 Generating Maven Wrapper..."
    mvn -N -q wrapper:wrapper -Dmaven=3.9.9
    chmod +x mvnw
fi

# 3. Helper to Standardize Service POMs
write_pom() {
    local path="$1"
    local aid="$2"
    local deps="$3"

    echo "   -> Standardizing $aid..."
    cat > "$path" <<EOF
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
    <artifactId>${aid}</artifactId>
    <version>0.1.0</version>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        ${deps}
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF
}

# 4. Define Dependency Blocks
DEPS_COMMON='<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency><dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency><dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>'
DEPS_JPA='<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency><dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency><dependency><groupId>org.flywaydb</groupId><artifactId>flyway-core</artifactId></dependency>'
DEPS_JWT='<dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>0.11.5</version></dependency><dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>0.11.5</version><scope>runtime</scope></dependency><dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>0.11.5</version><scope>runtime</scope></dependency><dependency><groupId>org.springframework.security</groupId><artifactId>spring-security-crypto</artifactId></dependency>'
DEPS_STRIPE='<dependency><groupId>com.stripe</groupId><artifactId>stripe-java</artifactId><version>24.0.0</version></dependency>'
DEPS_MONGO='<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-mongodb</artifactId></dependency>'
DEPS_AZURE='<dependency><groupId>com.azure</groupId><artifactId>azure-storage-blob</artifactId><version>12.27.0</version></dependency>'
DEPS_OPENAPI='<dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>'

# 5. Apply POMs
write_pom services/listings-service/pom.xml listings-service "${DEPS_COMMON}${DEPS_JPA}${DEPS_OPENAPI}"
write_pom services/auth-service/pom.xml auth-service "${DEPS_COMMON}${DEPS_JPA}${DEPS_JWT}"
write_pom services/users-service/pom.xml users-service "${DEPS_COMMON}${DEPS_JPA}${DEPS_JWT}"
write_pom services/payments-service/pom.xml payments-service "${DEPS_COMMON}${DEPS_STRIPE}"
write_pom services/media-service/pom.xml media-service "${DEPS_COMMON}${DEPS_AZURE}"
write_pom services/chat-service/pom.xml chat-service "${DEPS_COMMON}${DEPS_MONGO}"

# Gateway POM
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
    <build><plugins><plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin></plugins></build>
</project>
EOF

# 6. Verify Compile (Fast check)
echo "🏗️  Verifying Compile..."
./mvnw -q clean compile -pl services/auth-service,services/api-gateway -am

# 7. Push
echo "📤 Pushing..."
BRANCH="feature/fix-project-structure"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add .
git commit -m "chore: add root pom, standardize services, add maven wrapper" || echo "Nothing to commit"

if git push -u origin "$BRANCH"; then
    echo "✅ Success! Pushed to $BRANCH"
else
    echo "❌ Push failed."
fi
