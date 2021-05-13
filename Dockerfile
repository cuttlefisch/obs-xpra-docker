FROM ubuntu:20.04 as vgl-builder
MAINTAINER Joseph Lee <joseph@jc-lab.net>

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y \
    ca-certificates curl wget \
    build-essential cmake \
    libssl-dev libx11-dev libxext-dev libxtst-dev libgl-dev libglu1-mesa libglu1-mesa-dev libx11-xcb-dev libxcb1-dev libxcb-keysyms1-dev libxcb-glx0-dev libxv-dev libjpeg-turbo8-dev

COPY "libjpeg-turbo-2.0.6.tar.gz" "/work/libjpeg-turbo-2.0.6.tar.gz"
RUN mkdir -p /work/libjpeg-turbo/src /work/libjpeg-turbo/build && \
    cd /work/libjpeg-turbo/src && \
    tar --strip-components 1 -xf /work/libjpeg-turbo-2.0.6.tar.gz && \
    cd /work/libjpeg-turbo/build && \
    cmake /work/libjpeg-turbo/src
RUN cd /work/libjpeg-turbo/build && \
    cmake --build . -- -j4 && \
    cmake --install . --prefix /usr && \
    [ -f /usr/lib64/libturbojpeg.a ] && cp -rf /usr/lib64/* /usr/lib/ || true

COPY "VirtualGL-2.6.5.tar.gz" "/work/VirtualGL-2.6.5.tar.gz"
RUN mkdir -p /work/vgl/src /work/vgl/build && \
    cd /work/vgl/src && \
    tar --strip-components 1 -xf /work/VirtualGL-2.6.5.tar.gz && \
    cd /work/vgl/build && \
    cmake /work/vgl/src -DVGL_FAKEOPENCL=OFF
RUN cd /work/vgl/build && \
    cmake --build . -- -j4 && \
    DESTDIR=/work/vgl/dist cmake --install . --prefix /usr

RUN mkdir -p /work/vgl/dist/usr/lib/ && \
    [ -d /work/vgl/dist/usr/lib64 ] && cp -rf /work/vgl/dist/usr/lib64/* /work/vgl/dist/usr/lib/ || true && \
    cd /work/vgl/dist/usr && \
    tar -cvf /work/vgl/dist.tar bin lib doc

FROM ubuntu:20.04
MAINTAINER Joseph Lee <joseph@jc-lab.net>

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y \
    bash ca-certificates curl wget \
    git python3 \
    ffmpeg obs-studio xpra net-tools passwd \
    v4l-utils mesa-utils mesa-utils-extra fonts-noto-cjk

COPY --from=vgl-builder /work/vgl/dist.tar /tmp/vgl-dist.tar
RUN cd /usr/ && \
    tar -xf /tmp/vgl-dist.tar

ARG XPRA_HTML5_GIT_URL=https://github.com/Xpra-org/xpra-html5.git
ARG XPRA_HTML5_GIT_TAG=cfab323eecb65ad971ad621dfac0ca85c0856d56 # v4.1.2

RUN cd /tmp && \
    git clone ${XPRA_HTML5_GIT_URL} xpra-html5 && \
    cd xpra-html5 && \
    git checkout -f ${XPRA_HTML5_GIT_TAG} && \
    ./setup.py install /usr/share/xpra/www

ADD [ "entrypoint.sh", "run-x.sh", "xorg.conf", "/opt/" ]
RUN chmod +x /opt/*.sh && \
    echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' | tee /etc/profile.d/xdg.sh && \
    sed -i -e 's:allowed_users=console:allowed_users=anybody:g' /etc/X11/Xwrapper.config

RUN rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

VOLUME /root
WORKDIR /root

EXPOSE 10000/tcp
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD /opt/run-x.sh

