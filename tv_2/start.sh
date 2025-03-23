#!/bin/bash
docker stop tv-program-guide || true
docker rm tv-program-guide || true
docker build -t tv-program-guide .
docker run -d -p 8085:8085 --name tv-program-guide tv-program-guide
echo "Сервис ТВ Программа запущен на порту 8085"
echo "Откройте http://localhost:8085 в браузере" 