# Build stage
FROM node:16 as build
WORKDIR /src
RUN git clone https://github.com/tatsuyai713/sora.git
WORKDIR /src/sora

RUN corepack enable
RUN apt update &&apt install -y git-lfs
RUN git lfs install
RUN git lfs pull
RUN yarn install --immutable

RUN yarn run web:build:prod

# Main stage
FROM ubuntu:22.04

# Use noninteractive mode to skip confirmation when installing packages
ARG DEBIAN_FRONTEND=noninteractive
# Enable AppImage execution in a container
ENV APPIMAGE_EXTRACT_AND_RUN 1
# System defaults that should not be changed
ENV DISPLAY :0
ENV XDG_RUNTIME_DIR /tmp/runtime-user

# Default environment variables (password is "mypasswd")
ENV SIZEW 1920
ENV SIZEH 1080
ENV REFRESH 60
ENV DPI 96
ENV CDEPTH 24
ENV VGL_DISPLAY egl
ENV PASSWD mypasswd

# Set versions for components that should be manually checked before upgrading, other component versions are automatically determined by fetching the version online
ARG VIRTUALGL_VERSION=3.1


# Install locales to prevent X11 errors
RUN apt-get update && apt-get install -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

ENV TZ UTC
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install required packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    alsa-base \
    alsa-utils \
    apt-transport-https \
    apt-utils \
    build-essential \
    ca-certificates \
    cups-filters \
    cups-common \
    cups-pdf \
    curl \
    file \
    wget \
    bzip2 \
    gzip \
    p7zip-full \
    xz-utils \
    zip \
    unzip \
    zstd \
    gcc \
    git \
    jq \
    make \
    python3 \
    python3-pip \
    mlocate \
    nano \
    vim \
    htop \
    supervisor \
    libglvnd-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libgles2 \
    libglu1 \
    libsm6 \
    vainfo \
    vdpauinfo \
    pkg-config \
    mesa-utils \
    mesa-utils-extra \
    va-driver-all \
    xserver-xorg-input-all \
    xserver-xorg-video-all \
    mesa-vulkan-drivers \
    libvulkan-dev \
    libxau6 \
    libxdmcp6 \
    libxcb1 \
    libxext6 \
    libx11-6 \
    libxv1 \
    libxtst6 \
    xdg-utils \
    dbus-x11 \
    libdbus-c++-1-0v5 \
    xkb-data \
    x11-xkb-utils \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xauth \
    xbitmaps \
    xinit \
    xfonts-base \
    libxrandr-dev \
    # Install Xvfb, packages above this line should be the same between docker-nvidia-glx-desktop and docker-nvidia-egl-desktop
    xvfb \
    vulkan-tools && \
    rm -rf /var/lib/apt/lists/*
    


# install package
RUN apt-get update && apt-get install -y \
    build-essential \
    sudo \
    less \
    bash-completion \
    command-not-found \
    libglib2.0-0 \
    python3 \
    python3-pip \
    python3-dev \
    sed \
    ca-certificates \
    wget \
    gpg \
    gpg-agent \
    gpgconf \
    gpgv \
    locales \
    unzip \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    autoconf \
    gnupg \
    lsb-release \
    iproute2 \
    init \
    systemd \
    locales \
    iputils-ping \
    g++ \
    cmake \
    libdbus-1-dev \
    libpulse-dev \
    autoconf \
    automake \
    autotools-dev \
    chrpath \
    debhelper \
    jq \
    libc6-dev \
    libcairo2-dev \
    libjpeg-turbo8-dev \
    libssl-dev \
    libv4l-dev \
    libvncserver-dev \
    libtool-bin \
    libxdamage-dev \
    libxinerama-dev \
    libxrandr-dev \
    libxss-dev \
    libxtst-dev \
    libavahi-client-dev && \
rm -rf /var/lib/apt/lists/* && \
# Build the latest x11vnc source to avoid various errors
git clone https://github.com/tatsuyai713/x11vnc.git /tmp/x11vnc && \
cd /tmp/x11vnc && autoreconf -fi && ./configure && make install && cd / && rm -rf /tmp/* && \
git clone https://github.com/tatsuyai713/noVNC.git -b add_clipboard_support /opt/noVNC && \
ln -snf /opt/noVNC/vnc.html /opt/noVNC/index.html && \
# Use the latest Websockify source to expose noVNC
pip3 install git+https://github.com/tatsuyai713/websockify.git@v0.10.0

RUN add-apt-repository ppa:mozillateam/ppa

RUN { \
        echo 'Package: firefox*'; \
        echo 'Pin: release o=LP-PPA-mozillateam'; \
        echo 'Pin-Priority: 1001'; \
        echo ' '; \
        echo 'Package: firefox*'; \
        echo 'Pin: release o=Ubuntu*'; \
        echo 'Pin-Priority: -1'; \
    } > /etc/apt/preferences.d/99mozilla-firefox

RUN apt-get -y update \
    && apt-get install -y firefox

# Install Caddy
RUN apt install -y debian-keyring debian-archive-keyring apt-transport-https && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && \
    apt-get install -y caddy && \
    rm -rf /var/lib/apt/lists/*

# Install ROS 2 Humble
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | gpg --dearmor > /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && \
    apt-get install -y \
    ros-humble-ros-base \
    ros-dev-tools && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /ros2_ws/src
WORKDIR /ros2_ws
RUN git clone https://github.com/tatsuyai713/rws.git -b feature-humble-fastdds src/rws
RUN git clone https://github.com/tatsuyai713/ros2-websocket-proxy.git -b feature-humble-container src/ros2-websocket-proxy
RUN mkdir -p /ros2_ws/config

RUN apt-get update && \
    apt-get install -y \
    libwebsocketpp-dev libasio-dev && \
    rm -rf /var/lib/apt/lists/*
    
RUN . /opt/ros/humble/setup.sh && colcon build --symlink-install

WORKDIR /app
COPY --from=build /src/sora/web/.webpack ./

# Copy scripts and configurations used to start the container
COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 755 /etc/supervisord.conf

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*
