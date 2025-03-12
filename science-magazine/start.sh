#!/bin/bash
docker stop science-magazine || true
docker rm science-magazine || true
docker build -t science-magazine .
docker run -d -p 8082:8082 --name science-magazine science-magazine
echo "Сайт научного журнала запущен на порту 8082 http://localhost:8082 в браузере" 