ARG ARG_NODE_VERSION="12"
FROM node:${ARG_NODE_VERSION}

# Build arguments ...

# Node.js version
ARG ARG_NODE_VERSION

# Version information
# Major Node.js version information will be used as major image version!
ARG ARG_IMAGE_VERSION="1.0" 

# S6-Overlay
ARG ARG_S6_OVERLAY_VERSION="2.2.0.3"

# The commit sha triggering the build.
ARG ARG_APP_COMMIT

# Basic build-time metadata as defined at http://label-schema.org
LABEL \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="MiGoller" \
    org.label-schema.vendor="MiGoller" \
    org.label-schema.version="${ARG_NODE_VERSION}.${ARG_IMAGE_VERSION}" \
    org.label-schema.description="ioBroker - Automate your life" \
    org.label-schema.url="https://github.com/MiGoller/iobroker-docker" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-ref="${ARG_APP_COMMIT}" \
    org.label-schema.vcs-url="https://github.com/MiGoller/iobroker-docker.git" \
    maintainer="MiGoller" \
    Author="MiGoller" \
    org.opencontainers.image.source="https://github.com/MiGoller/iobroker-docker"

# Default environment variables
ENV \
    DEBIAN_FRONTEND="noninteractive" \
    IMAGE_VERSION="${ARG_NODE_VERSION}.${ARG_IMAGE_VERSION}" \
    S6_OVERLAY_VERSION=${ARG_S6_OVERLAY_VERSION}

# Install prerequisites
RUN \
    # Install prerequisites
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        acl \
        apt-utils \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        libcap2-bin \
        libpam0g-dev \
        libudev-dev \
        locales \
        procps \
        python \
        sudo \
        unzip \
        tar \
        tzdata \
        wget \
        # Avahi-Daemon
        libavahi-compat-libdnssd-dev \
        avahi-daemon \
        avahi-utils \
        libnss-mdns \
        # CIFS and NFS support for Backitup
        cifs-utils nfs-common \
    # Install node-gyp - Node.js native addon build tool
    && npm install -g node-gyp \
    # Generate locales en_US.UTF-8 and de_DE.UTF-8
    && sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    # Clean up installation cache
    && rm -rf /var/lib/apt/lists/*

# Install S6-Overlay
RUN \
    # Determine S6 arch to download and to install
    S6_ARCH="" \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) S6_ARCH='amd64';; \
        ppc64el) S6_ARCH='ppc64le';; \
        arm64) S6_ARCH='armhf';; \
        arm) S6_ARCH='arm';; \
        armel) S6_ARCH='arm';; \
        armhf) S6_ARCH='armhf';; \
        i386) S6_ARCH='x86';; \
        *) echo "Unsupported architecture for S6: ${dpkgArch}"; exit 1 ;; \ 
    esac \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v${ARG_S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    && echo "S6 Overlay v${ARG_S6_OVERLAY_VERSION} (${S6_ARCH} for dpkArch ${dpkgArch}) installed on ${BUILDPLATFORM} for ${TARGETPLATFORM}."

# Install ioBroker
# Building on GitHub CI will fail with CAP_NET_ADMIN set !
# Since the build runs on Docker we will simply remove it from install.sh .
RUN curl -sL https://iobroker.net/install.sh | sed -e 's/cap_net_admin,//' | bash - \
    && echo $(hostname) > /opt/iobroker/.install_host \
    && rm -rf /var/lib/apt/lists/* \
    # Setup iobroker user \
    && chsh -s /bin/bash iobroker \
    && echo "ioBroker installed."

WORKDIR /opt/iobroker

# Backup initial ioBroker setup
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker

# Essential environment variables for the ioBroker runtime
ENV \
    # S6-Overlay tweaks
    S6_KILL_FINISH_MAXTIME=15000 \
    S6_SERVICES_GRACETIME=15000 \
    S6_KILL_GRACETIME=15000 \
    # Localization
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Europe/Berlin \
    # Additional packages to install
    PACKAGES="" \
    # Device permissions
    USBDEVICES="" \
    # ioBroker adapter related stuff
    IOB_ADMINPORT="" \
    IOB_DISABLE_SENTRY=""

# Copy S6-overlay files...
COPY ./s6_overlay/etc /etc/

# Copy scripts
COPY ./scripts /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Setup exposed volumes and ports
VOLUME [ "/opt/iobroker" ]

EXPOSE 8081 8082 8083 8084

# Setup healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["/bin/bash", "-c", "/opt/scripts/docker_healthcheck.sh"]

# Set container entrpoint to S6-Overlay!
ENTRYPOINT ["/init"]
