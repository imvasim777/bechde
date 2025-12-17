#!/bin/bash
echo '🚀 Starting API Gateway...'
cd "/Users/user/IdeaProjects/bechde/services/api-gateway"
mvn spring-boot:run -Dspring-boot.run.profiles=local
