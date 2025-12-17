#!/bin/bash
echo '🚀 Starting Users on port 8083...'
cd "/Users/user/IdeaProjects/bechde/services/users-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8083 -Dspring.datasource.url=jdbc:postgresql://localhost:5432/bechde -Dspring.datasource.username=bechde -Dspring.datasource.password=bechde -DJWT_SECRET=local-dev-secret-must-be-long-enough-for-hs256-signing"
