#!/bin/bash

docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
docker build -t spellcheck-system .
docker run -d -p 8080:8080 spellcheck-system

echo "Система проверки правописания запущена на http://localhost:8080/" 