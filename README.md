# Docker for NXP MCUXpresso
This project contains a blueprint for using NXP MCUXpresso with docker.
It includes DevContainer files for VS Code, plus docker files to use and share in a CI/CD environment.


The image is available on dockerhub: https://hub.docker.com/repository/docker/erichstyger/nxp-mcuxpresso-image/general

## Content
The image/container includes the following:
- Toolchain for ARM Cortex-M, including CMake and Ninja
- Debugging tools: NXP LinkServer, SEGGER J-Link and PEMicro (P&E)
- NXP MCUXpresso Installer to install extra components if needed
- NXP Config tools with offline data files
- all other necessary tools for development

## NXP Config Tools
If you want to rebuild the image with the NXP config tools:

- download the DEB package from https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/mcuxpresso-config-tools-pins-clocks-and-peripherals:MCUXpresso-Config-Tools
- place in this directory and name it `mcuxpresso-config-tools-26.09-1_amd64.deb`


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

## Push on dockerhub
Login first (can use docker desktop first):
```
docker login
```
Create a tagged image:
```
docker tag nxp-mcuxpresso-image erichstyger/nxp-mcuxpresso-image:v2
```
additionally, tag it as the latest version:
```
docker tag nxp-mcuxpresso-image erichstyger/nxp-mcuxpresso-image:latest
```

Push it to the dockerhub repository:
```
docker push erichstyger/nxp-mcuxpresso-image:v2
docker push erichstyger/nxp-mcuxpresso-image:latest
```

Pulling an image from the repository on https://hub.docker.com/:
```
docker pull erichstyger/nxp-mcuxpresso-image:v2
docker pull erichstyger/nxp-mcuxpresso-image:latest
```

