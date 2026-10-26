# Docker file for VS Code using a DevContainer

FROM mcr.microsoft.com/devcontainers/cpp:dev-ubuntu24.04

# folder for downloaded files
WORKDIR /apps
RUN mkdir -p /apps

# Create user directory, needed by MCUXpresso tools. Directory has to be owned by the user which is 'vsocde'
USER vscode
RUN mkdir -p /home/vscode
# switch back to root
USER root

# Set your host machine architecture with ARG, just set one and comment the other one:
ARG HOST_MACHINE="x86"
#ARG HOST_MACHINE="arm"

ARG HOST_MACHINE_X64_ARM64="x64"
#ARG HOST_MACHINE_X64_ARM64="arm64"

ARG HOST_MACHINE_INTEL64_ARM64="x86_64"
#ARG HOST_MACHINE_INTEL64_ARM64="arm64"

#####################################################################################################
# Install prerequisites
RUN \
    apt-get update \
    && apt-get install -y git wget unzip nano iputils-ping file \
    && apt-get install -y python3 python3-pip python3-venv \
    && apt-get install -y cmake build-essential ninja-build \
    && apt-get install -y gcc-arm-none-eabi gdb-arm-none-eabi libnewlib-arm-none-eabi \
    && apt-get install -y doxygen graphviz \
    && apt-get install -y apt-transport-https ca-certificates curl software-properties-common \
    && apt-get install -y libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
    && apt-get install -y libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 \
    && apt-get install -y libxcb-xkb1 libxkbcommon-x11-0 libxkbcommon0 xkb-data \
    && apt-get install -y udev


#####################################################################################################
# Install the more recent CMake version, as the Ubuntu 24.04 comes with 3.28.3
ARG CMAKE_VERSION=3.30.9
RUN wget -q \
      https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
      -O /apps/cmake.tar.gz \
    && mkdir -p /opt/cmake \
    && tar -xzf /apps/cmake.tar.gz \
       --strip-components=1 \
       -C /opt/cmake
ENV PATH="/opt/cmake/bin:${PATH}"


#####################################################################################################
# Install Ninja 1.13.2
ARG NINJA_VERSION=1.13.2
RUN curl -fL \
       https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip \
       -o /apps/ninja.zip \
    && unzip -o /apps/ninja.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/ninja


#####################################################################################################
# Get a specific version of the arm toolchain
ARG TOOLCHAIN_VERSION="15.2.1-1.1"
# x86:              xpack-arm-none-eabi-gcc-${TOOLCHAIN_VERSION}-linux-x86.tar.gz
# Apple silicon:    xpack-arm-none-eabi-gcc-${TOOLCHAIN_VERSION}-linux-arm64.tar.gz
RUN \
    cd /apps \
    && wget https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v${TOOLCHAIN_VERSION}/xpack-arm-none-eabi-gcc-${TOOLCHAIN_VERSION}-linux-${HOST_MACHINE_X64_ARM64}.tar.gz -O gcc-arm-none-eabi.tar.gz \
    && mkdir /opt/gcc-arm-none-eabi-${TOOLCHAIN_VERSION} \
    && tar -xvzf gcc-arm-none-eabi.tar.gz -C /opt/gcc-arm-none-eabi-${TOOLCHAIN_VERSION} --strip-components 1 \
    && rm gcc-arm-none-eabi.tar.gz \
    && ln -s /opt/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}/bin/* /usr/local/bin


#####################################################################################################
# Coverage support with gcov and gcvor
# for gcov, have to use the one matching for arm-none-eabi-gcov
RUN \
    rm /usr/bin/gcov \
    && cd /usr/bin \
    && ln -s /opt/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}/bin/arm-none-eabi-gcov gcov
# install gcvor in local virtual environment
RUN \
    cd /apps \
    && python3 -m venv venv \
    && ./venv/bin/pip install gcovr
# add location of gcovr inside the virtual environment to the path
ENV PATH="/apps/venv/bin:${PATH}"


#####################################################################################################
# Python dependencies for NXP MCUXpresso SDK
RUN /apps/venv/bin/python -m pip install --no-cache-dir \
    PyYAML \
    jsonschema \
    pykwalify


#####################################################################################################
# Install SEGGER debugging tools
# for x86:           JLink_Linux_V980_x86_64.deb
# for Apple silicon: JLink_Linux_V980_arm64.deb
ARG SEGGER_VERSION="V980"
RUN \
    cd /apps \
    && curl -d "accept_license_agreement=accepted&submit=Download+software" -X POST -O "https://www.segger.com/downloads/jlink/JLink_Linux_${SEGGER_VERSION}_${HOST_MACHINE_INTEL64_ARM64}.deb" 
# in case issue with mismatch between J-Link version between host and container/image: use matching version
# issue with udev, see https://forum.segger.com/index.php/Thread/8953-SOLVED-J-Link-Linux-installer-fails-for-Docker-containers-Error-Failed-to-update/
RUN \
    cd /apps \
    && dpkg --unpack JLink_Linux_${SEGGER_VERSION}_${HOST_MACHINE_INTEL64_ARM64}.deb \
    && rm -f /var/lib/dpkg/info/jlink.postinst \
    && dpkg --configure jlink \
    && apt install -yf


#####################################################################################################
# Download and install MCUXpresso Installer
# x86:              MCUXpressoInstaller.deb.bin
# Apple silicon:    MCUXpressoInstaller_arm64.dmg
# INFO: Installation directory: /home/vscode/MCUXpressoInstaller
# INFO: To start the installer, run /home/vscode/MCUXpressoInstaller/MCUXpressoInstaller
# install package to elevate user permissions for installation
RUN \
    apt-get update \
    && apt-get install -y policykit-1
RUN if [ "$HOST_MACHINE" = "x86" ]; then \
        URL="https://www.nxp.com/lgfiles/updates/mcuxpresso/MCUXpressoInstaller.deb.bin"; \
    else \
        URL="https://www.nxp.com/lgfiles/updates/mcuxpresso/MCUXpressoInstaller_arm64.dmg"; \
    fi; \
    curl -fL -o /apps/mcuxpresso-installer "$URL";
RUN \
    cd /apps \
    && chmod a+x mcuxpresso-installer
# Install as vscode user
USER vscode
RUN mkdir -p /home/vscode/.local/share/applications
RUN sudo /apps/mcuxpresso-installer
# Back as root
USER root
# need to set the following variable for the Installer GUI to work
ENV XDG_SESSION_TYPE=wayland
# Install needed libraries to run the MCUXpresso Installer GUI
# NOTE that while this will run the GUI in the container (WSL in my case), this is not supported by NXP
# Files are only installed so one can use the 'Open MCUXpresso Installer' from the NXP extension.
RUN \
    sudo apt-get update \
    && sudo apt-get install -y \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
        libdrm2 libgbm1 libxkbcommon0 \
        libgtk-3-0 libgdk-pixbuf-2.0-0 \
        libcairo2 libcairo-gobject2 \
        libpango-1.0-0 libpangocairo-1.0-0 libharfbuzz0b libglib2.0-0 \
        libx11-6 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
        libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
        libx11-xcb1 libxcb1 libxcb-dri3-0 libasound2t64\
        libfontconfig1 fonts-liberation \
        libcups2 libdbus-1-3 libexpat1 libssl3
# ---------------------------------------------------------------------------
# Passwordless sudo through a dedicated group, and a pkexec replacement for
# the npm "sudo-prompt" library (used by the MCUXpresso Installer). The real
# pkexec needs polkitd, dbus and a polkit authentication agent, none of
# which run inside a container (no systemd-logind session).
# ---------------------------------------------------------------------------
# Group whose members can use sudo without being asked for a password
RUN groupadd -f sudonopasswd \
    && usermod -aG sudonopasswd vscode \
    && echo '%sudonopasswd ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-sudonopasswd \
    && chmod 440 /etc/sudoers.d/90-sudonopasswd \
    && visudo -c
# Install the pkexec replacement at the exact path sudo-prompt checks.
# dpkg-divert prevents a later 'apt install pkexec' from overwriting it.
COPY pkexec-shim.sh /tmp/pkexec-shim.sh
RUN dpkg-divert --local --rename --add /usr/bin/pkexec \
    && install -m 755 /tmp/pkexec-shim.sh /usr/bin/pkexec \
    && sed -i 's/\r$//' /usr/bin/pkexec \
    && rm /tmp/pkexec-shim.sh


#####################################################################################################
# Create directories expected by the MCUXpresso VS Code extension:
USER vscode
RUN \
       mkdir -p /home/vscode/.mcuxpressotools/.mcux-venv-3.12/bin/ \
    && mkdir -p /home/vscode/.mcuxpressotools/mcux-fixelf-14.2.2/
# Back to root
USER root


#####################################################################################################
# Install the MCUXpresso Config tools
# Install MCUXpresso Config Tools
# The installer is downloaded manually from NXP.
# installed as /opt/nxp/MCUX_CFG_26.09/bin/tools
# Prepare MIME database before installing MCUXpresso Config Tools
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       shared-mime-info \
    && update-mime-database /usr/share/mime \
    && dpkg --configure -a
COPY mcuxpresso-config-tools*.deb.bin /apps/config-tools-installer.deb.bin
RUN \
    cd /apps \
    && chmod +x /apps/config-tools-installer.deb.bin \
    && /apps/config-tools-installer.deb.bin -- -s \
    && dpkg --configure -a
# Copy and extract the MCU data files for offline usage
COPY config_data.zip /apps/config_data.zip
# Install as vscode user
USER vscode
RUN \
    mkdir -p /home/vscode/.nxp/ \
    && unzip -q /apps/config_data.zip -d /home/vscode/.nxp
# Back as root
USER root

#####################################################################################################
# Download and install PEMICRO debug software
# Note: file name with "10110000" means v10.11
RUN \
    apt-get install -y libusb-0.1-4
RUN \
    cd /apps \
    && wget -O pemicro-gdb.deb "https://www.pemicro.com/fixedlinks/pemicrogdbserver_10110000_x64.deb" 
# installing the .deb file without the postinst script inside the package: need to set USB drivers on the host.
RUN dpkg-deb -x /apps/pemicro-gdb.deb / \
    && chmod 755 /usr/local/pemicrogdbserver/pegdbserver_console \
    && chmod 755 /usr/local/pemicrogdbserver/gdb/arm-none-eabi-gdb \
    && chmod 755 /usr/local/pemicrogdbserver/drivers/libp64-0.1.so.4 \
    && install -m 755 \
       /usr/local/pemicrogdbserver/drivers/libp64-0.1.so.4 \
       /usr/lib/libp64-0.1.so.4 \
    && ldconfig
# add to path
ENV PATH="/usr/local/pemicrogdbserver:/usr/local/pemicrogdbserver/gdb:${PATH}"

#####################################################################################################
# Install NXP LinkServer software
# which version to use:
ARG LINKSERVER_VERSION="26.9.130"
# x86:              LinkServer_${LINKSERVER_VERSION}.x86_64.deb.bin
# Apple silicon:    LinkServer_${LINKSERVER_VERSION}.arm64.dmg
# Install LinkServer dependencies. USB udev rules are managed by the Docker host.
RUN apt-get update \
    && apt-get install -y whiptail libusb-1.0-0-dev dfu-util usbutils hwdata \
       gir1.2-webkit2-4.1 libwebkit2gtk-4.1-0 gir1.2-gtk-3.0

# install LinkServer software
# it gets installed into /usr/local/LinkServer_${LINKSERVER_VERSION}
RUN if [ "$HOST_MACHINE" = "x86" ]; then \
        URL="https://www.nxp.com/lgfiles/updates/mcuxpresso/LinkServer_${LINKSERVER_VERSION}.${HOST_MACHINE_INTEL64_ARM64}.deb.bin"; \
    else \
        URL="https://www.nxp.com/lgfiles/updates/mcuxpresso/LinkServer_${LINKSERVER_VERSION}.${HOST_MACHINE_INTEL64_ARM64}.dmg"; \
    fi; \
    curl -fL -o /apps/linkserver-installer "$URL";
# The NXP .deb postinst scripts reload udev rules, which fails in a DevContainer.
# Temporarily shadow udevadm only for the reload-rules operation, and always
# restore the original executable before ending this build step.
RUN set -eu; \
    cd /apps; \
    chmod a+x linkserver-installer; \
    mkdir -p /tmp/nxp-udev-shim; \
    printf '%s\n' '#!/bin/sh' \
      'if [ "$1" = "control" ] && [ "${2:-}" = "--reload-rules" ]; then exit 0; fi' \
      'exec /usr/bin/udevadm "$@"' > /tmp/nxp-udev-shim/udevadm; \
    chmod +x /tmp/nxp-udev-shim/udevadm; \
    PATH="/tmp/nxp-udev-shim:$PATH" ./linkserver-installer acceptLicense skipIdeSelect; \
    PATH="/tmp/nxp-udev-shim:$PATH" dpkg --configure -a; \
    rm -rf /tmp/nxp-udev-shim; \
    dpkg --audit
# add LinkServer to the PATH
ENV PATH="/usr/local/LinkServer_${LINKSERVER_VERSION}:${PATH}"

#####################################################################################################
# Download and install addditional NXP debugger support
RUN \
    cd /apps \
    && wget -O debug_common.tar "https://www.nxp.com/lgfiles/updates/mcuxpresso/debug_common-26.09.tar"
USER vscode
RUN \
    mkdir -p /home/vscode/.mcuxpressotools/debug_common-26.09 \
    && tar -xf /apps/debug_common.tar -C /home/vscode/.mcuxpressotools/debug_common-26.09
# back to root
USER root

#####################################################################################################
# Install SSH client for private GitHub submodules
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-client

#####################################################################################################
# Set environment variables needed: 
# where the MCUXpresso SDK is located:
ENV MCUXPRESSO_SDK_PATH=/workspace/sdk/
# where the toolchain (e.g. arm-none-eabi-gcc) is located
ENV TOOLCHAIN_PATH=/usr/local
# user home directory. USERPROFILE exists by default on Windows
ENV USERPROFILE=/home/vscode
# path to the SEGGER programs
ENV SEGGER_PATH=/opt/SEGGER/JLink
ENV SEGGER_GDB_SERVER="$SEGGER_PATH/JLinkGDBServerCLExe"

# Command that will be invoked when the container starts
# ENTRYPOINT ["/bin/bash"]
CMD ["/bin/bash"]
