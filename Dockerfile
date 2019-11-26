###
# Build image
###
FROM alpine:edge AS build
#FROM alpine:3.9 AS build
#FROM alpine:edge

ENV XMR_STAK_VERSION 2.10.7

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
RUN apk add --upgrade apk-tools@edge
RUN git clone https://github.com/fireice-uk/xmr-stak.git \
    && cd xmr-stak \
    && git checkout tags/${XMR_STAK_VERSION} -b build  \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' xmrstak/donate-level.hpp \
    \
    && cmake . -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF -DHWLOC_ENABLE=ON -DXMR-STAK_COMPILE=generic \
    && make -j$(nproc) \
    \
    && cp -t /app bin/xmr-stak \
    && chmod 777 -R /app \
    && dos2unix -u /app/docker-entrypoint.sh
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
FROM alpine:edge
#FROM alpine:3.6

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

