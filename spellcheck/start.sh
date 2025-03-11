#!/bin/bash
docker stop spellcheck-service || true
docker rm spellcheck-service || true
docker build -t spellcheck-service .
docker run -d -p 8081:8081 --name spellcheck-service spellcheck-service
echo "Сервис проверки правописания запущен на порту 8081"
echo "Откройте http://localhost:8081 в браузере" 