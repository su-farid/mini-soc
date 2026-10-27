docker run -d -p 80:80 --name mycontainer nginx:latest
curl localhost
docker ps
docker stop mycontainer
docker ps
docker ps -a
docker inspect mycontainer | head -40
docker start mycontainer && docker ps
docker restart mycontainer && docker ps
docker stop mycontainer
docker rm mycontainer
docker ps -a
docker images
docker inspect nginx:latest | head -40
docker tag nginx:latest mynginx:v1
docker images
docker rmi mynginx:v1
docker image prune
docker system prune -a
