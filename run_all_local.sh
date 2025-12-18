#!/usr/bin/env bash

# Script: run_all_local.sh
# Description: Starts local infra (Docker) and launches all Bechde microservices.
# Platform: macOS
# Fixes: Uses temporary launcher scripts to bypass AppleScript quoting errors.

set -e

# --- Configuration ---
DB_URL="jdbc:postgresql://localhost:5432/bechde"
DB_USER="bechde"
DB_PASS="bechde"
JWT_SECRET="local-dev-secret-must-be-long-enough-for-hs256-signing"
JWT_TTL="3600"
MONGO_URI="mongodb://localhost:27017/bechde"
WORK_DIR=$(pwd)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Bechde Local Environment...${NC}"

# 1. Prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker missing"; exit 1; }
command -v mvn >/dev/null 2>&1 || { echo "❌ Maven missing"; exit 1; }
mkdir -p .launchers # Temp dir for launcher scripts

# 2. Infra
echo -e "${GREEN}🐳 Starting Postgres & MongoDB...${NC}"
cat > docker-compose.dev.yml <<EOF
version: "3.8"
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: bechde
      POSTGRES_PASSWORD: bechde
      POSTGRES_DB: bechde
    ports: ["5432:5432"]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U bechde"]
      interval: 5s
      timeout: 5s
      retries: 10
  mongo:
    image: mongo:6
    ports: ["27017:27017"]
    healthcheck:
      test: ["CMD","mongosh","--eval","db.adminCommand('ping')"]
      interval: 5s
      timeout: 5s
      retries: 10
EOF
docker compose -f docker-compose.dev.yml up -d
echo "⏳ Waiting 5s for DB..."
sleep 5

# 3. Config
echo -e "${GREEN}⚙️  Configuring API Gateway...${NC}"
mkdir -p services/api-gateway/src/main/resources
cat > services/api-gateway/src/main/resources/application-local.yml <<EOF
server:
  port: 8080
spring:
  cloud:
    gateway:
      routes:
        - id: listings
          uri: http://localhost:8081
          predicates: [ Path=/listings/** ]
        - id: auth
          uri: http://localhost:8082
          predicates: [ Path=/auth/** ]
        - id: users
          uri: http://localhost:8083
          predicates: [ Path=/users/** ]
        - id: payments
          uri: http://localhost:8084
          predicates: [ Path=/payments/** ]
        - id: media
          uri: http://localhost:8085
          predicates: [ Path=/media/** ]
        - id: chat
          uri: http://localhost:8086
          predicates: [ Path=/chats/** ]
EOF

# 4. Helper Function (Robust Launcher)
launch_service() {
    NAME=$1
    SUB_DIR=$2
    PORT=$3
    # Use "$*" to capture all remaining arguments as one string for JVM args
    shift 3
    ARGS="$*"

    LAUNCHER=".launchers/start_$NAME.sh"

    # Create a temporary script for this service
    echo "#!/bin/bash" > "$LAUNCHER"
    echo "echo '🚀 Starting $NAME on port $PORT...'" >> "$LAUNCHER"
    echo "cd \"$WORK_DIR/$SUB_DIR\"" >> "$LAUNCHER"
    # Escaping for the JVM arguments inside the launcher
    echo "mvn spring-boot:run -Dspring-boot.run.jvmArguments=\"-Dserver.port=$PORT $ARGS\"" >> "$LAUNCHER"

    chmod +x "$LAUNCHER"

    echo "   ▶️  Launching $NAME ($PORT)..."
    osascript -e "tell application \"Terminal\" to do script \"$WORK_DIR/$LAUNCHER\"" > /dev/null
}

# 5. Launch
echo -e "${GREEN}🔥 Firing up Microservices (Check new Terminal windows)...${NC}"

launch_service "Listings" "services/listings-service" "8081" \
"-Dspring.datasource.url=$DB_URL -Dspring.datasource.username=$DB_USER -Dspring.datasource.password=$DB_PASS"

launch_service "Auth" "services/auth-service" "8082" \
"-Dspring.datasource.url=$DB_URL -Dspring.datasource.username=$DB_USER -Dspring.datasource.password=$DB_PASS -DJWT_SECRET=$JWT_SECRET -DJWT_TTL_SECONDS=$JWT_TTL"

launch_service "Users" "services/users-service" "8083" \
"-Dspring.datasource.url=$DB_URL -Dspring.datasource.username=$DB_USER -Dspring.datasource.password=$DB_PASS -DJWT_SECRET=$JWT_SECRET"

launch_service "Payments" "services/payments-service" "8084" ""

launch_service "Media" "services/media-service" "8085" ""

launch_service "Chat" "services/chat-service" "8086" \
"-Dspring.data.mongodb.uri=$MONGO_URI"

# Gateway (Last)
echo "   ▶️  Launching API Gateway (8080)..."
GATEWAY_LAUNCHER=".launchers/start_Gateway.sh"
echo "#!/bin/bash" > "$GATEWAY_LAUNCHER"
echo "echo '🚀 Starting API Gateway...'" >> "$GATEWAY_LAUNCHER"
echo "cd \"$WORK_DIR/services/api-gateway\"" >> "$GATEWAY_LAUNCHER"
echo "mvn spring-boot:run -Dspring-boot.run.profiles=local" >> "$GATEWAY_LAUNCHER"
chmod +x "$GATEWAY_LAUNCHER"

osascript -e "tell application \"Terminal\" to do script \"$WORK_DIR/$GATEWAY_LAUNCHER\"" > /dev/null

echo -e "${BLUE}✅ Done! All services are starting up in separate windows.${NC}"
