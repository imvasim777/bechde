#!/bin/bash
echo '🚀 Starting Payments on port 8084...'
cd "/Users/user/IdeaProjects/bechde/services/payments-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8084 "
