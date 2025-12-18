#!/bin/bash
echo '🚀 Starting Listings on port 8081...'
cd "/Users/user/IdeaProjects/bechde/services/listings-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8081 -Dspring.datasource.url=jdbc:postgresql://localhost:5432/bechde -Dspring.datasource.username=bechde -Dspring.datasource.password=bechde"
