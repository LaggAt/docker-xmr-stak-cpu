###
# Build image
###
#FROM alpine:edge AS build
FROM alpine:3.10.0 AS build
#FROM alpine:edge

ENV XMR_STAK_VERSION 1.0.0-rx

COPY app /app

WORKDIR /usr/local/src

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd-dev \
      libcrypto1.1 \
      openssl-dev \
      hwloc-dev@testing \
      numactl@edge \
      build-base \
      cmake \
      coreutils \
      git

RUN git clone https://github.com/fireice-uk/xmr-stak.git \
    && cd xmr-stak \
    && git checkout tags/${XMR_STAK_VERSION} -b build  \
    \
    && cmake . -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF -DHWLOC_ENABLE=ON -DXMR-STAK_COMPILE=generic \
    && make -j$(nproc) \
    && ls -la /app \
    \
    && cp -t /app bin/xmr-stak-rx \
    && chmod 777 -R /app
RUN apk del --no-cache --purge \
      libmicrohttpd-dev \
      openssl-dev \
      hwloc-dev@testing \
      build-base \
      cmake \
      coreutils \
      git || echo "apk purge error ignored"

###
# Deployed image
###
#FROM alpine:edge
FROM alpine:3.10.0

WORKDIR /app

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd \
      openssl \
      hwloc@testing \
      python2 \
      py2-pip \
      libstdc++ \
      && pip install envtpl

COPY --from=build app .

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["xmr-stak-cpu"]

