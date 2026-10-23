# Docker for NXP MCUXpresso
This project contains a blueprint for using NXP MCUXpresso with docker.
It includes DevContainer files for VS Code, plus docker files to use and share in a CI/CD environment.

## Using Docker
- install docker from [www.docker.com](https://www.docker.com/) and have it running
- open a consoel and `cd` to this folder and create docker image:
```
docker build -t nxp-mcuxpresso-image .
```
- create container from image:
```
docker create -i -t --name nxp-mcuxpresso-container nxp-mcuxpresso-image
```
- start the container:
```
docker start -i nxp-mcuxpresso-container
```

## push on dockerhub
Login first (can use docker desktop first):
```
docker login
```
Create a tagged image:
```
docker tag nxp-mcuxpresso-image erichstyger/nxp-mcuxpresso-image:v1
```

Push it to the dockerhub repository:
```
docker push erichstyger/nxp-mcuxpresso-image:v1
```

Pulling an image from the repository (https://hub.docker.com/):
```
docker pull erichstyger/nxp-mcuxpresso-image:v1
```

