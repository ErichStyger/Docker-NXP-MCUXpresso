# Docker file for VS Code using a DevContainer
# using https://github.com/ErichStyger/Docker-NXP-MCUXpresso

FROM erichstyger/nxp-mcuxpresso-image:latest

#####################################################################################################
# SEGGER SystemView, binary gets installed as /opt/SEGGER/SystemView_${SYSTEMVIEW_VERSION}/SystemView
# On your Ubuntu host, run the following to grant SystemView access to the X server:
# xhost +si:localuser:$(id -un)
# the above is can be done in the devcontainer.json for VS Code
ARG SYSTEMVIEW_VERSION="V410b"
RUN \
    cd /apps \
    && wget -O SystemView.deb \
       https://www.segger.com/downloads/systemview/SystemView_Linux_${SYSTEMVIEW_VERSION}_x86_64.deb \
    && apt-get install ./SystemView.deb
RUN rm /apps/SystemView.deb
ENV PATH="/opt/SEGGER/SystemView_${SYSTEMVIEW_VERSION}/:${PATH}"

