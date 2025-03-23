#!/bin/bash

# Stop and remove only the translation-system container if it exists
docker stop translation-system 2>/dev/null || true
docker rm translation-system 2>/dev/null || true

# Remove the old image if it exists
docker rmi translation-system 2>/dev/null || true

# Build and run the new image
docker build -t translation-system .
docker run -d -p 8080:8080 --name translation-system translation-system

echo "Translation system is running at http://localhost:8080"