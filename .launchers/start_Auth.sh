#!/bin/bash
echo '🚀 Starting Auth on port 8082...'
cd "/Users/user/IdeaProjects/bechde/services/auth-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8082 -Dspring.datasource.url=jdbc:postgresql://localhost:5432/bechde -Dspring.datasource.username=bechde -Dspring.datasource.password=bechde -DJWT_SECRET=local-dev-secret-must-be-long-enough-for-hs256-signing -DJWT_TTL_SECONDS=3600"
