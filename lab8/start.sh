docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
docker build -t translation-system .
docker run -d -p 8080:8080 translation-system