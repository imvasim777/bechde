#!/bin/bash
echo '🚀 Starting Chat on port 8086...'
cd "/Users/user/IdeaProjects/bechde/services/chat-service"
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8086 -Dspring.data.mongodb.uri=mongodb://localhost:27017/bechde"
