#!/bin/bash
echo '🚀 Starting Media on port 8085...'
cd "/Users/user/IdeaProjects/bechde/services/media-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8085 "
