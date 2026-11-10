# Docker for NXP MCUXpresso
This project contains a blueprint for using NXP MCUXpresso with docker.
It includes DevContainer files for VS Code, plus docker files to use and share in a CI/CD environment.


The image is available on dockerhub: https://hub.docker.com/repository/docker/erichstyger/nxp-mcuxpresso-image

Additionally, read my blog articles on that subject:
- All‑in‑One Docker Image for NXP MCUXpresso, VS Code and CI/CD Pipeline: https://mcuoneclipse.com/2026/10/25/all-in-one-docker-image-for-nxp-mcuxpresso-vs-code-and-ci-cd-pipeline/ 
- Offline VS Code DevContainers with Preinstalled Extensions: https://mcuoneclipse.com/2026/11/08/offline-vs-code-devcontainers-with-preinstalled-extensions/

## Content
The image/container includes the following:
- Toolchain for ARM Cortex-M, including CMake and Ninja
- Debugging tools: NXP LinkServer, SEGGER J-Link and PEMicro (P&E)
- NXP MCUXpresso Installer to install extra components if needed
- Optionally install NXP Config tools with offline data files
- all other necessary tools for development

## NXP Config Tools
Optionally, if you want to build the image with the NXP config tools.
The tools are not included here, as you have to download them from the link below and accept the licensing terms first.

- download the DEB package from https://www.nxp.com/design/design-center/software/development-software/mcuxpresso-software-and-tools-/mcuxpresso-config-tools-pins-clocks-and-peripherals:MCUXpresso-Config-Tools
- place it into the 'config-tools' directory and name so it matches `mcuxpresso-config-tools*.deb.bin`
- place any config tools offline data files into the 'config-tools' folder


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
docker tag nxp-mcuxpresso-image erichstyger/nxp-mcuxpresso-image:v3
```
additionally, tag it as the latest version:
```
docker tag nxp-mcuxpresso-image erichstyger/nxp-mcuxpresso-image:latest
```

Push it to the dockerhub repository:
```
docker push erichstyger/nxp-mcuxpresso-image:v3
docker push erichstyger/nxp-mcuxpresso-image:latest
```

Pulling an image from the repository on https://hub.docker.com/:
```
docker pull erichstyger/nxp-mcuxpresso-image:v3
docker pull erichstyger/nxp-mcuxpresso-image:latest
```

## Using the image from dockerhub
```
docker pull erichstyger/nxp-mcuxpresso-image:latest
```

```
docker create -i -t --name nxp-mcuxpresso-container erichstyger/nxp-mcuxpresso-image
```

```
docker start -i nxp-mcuxpresso-container
```


I hope this is useful,

Erich