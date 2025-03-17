#!/bin/bash
docker stop matrix-service || true
docker rm matrix-service || true
docker build -t matrix-service .
docker run -d -p 8083:8083 --name matrix-service matrix-service
echo "Сервис матричных вычислений запущен на порту 8083"
echo "Откройте http://localhost:8083 в браузере" 