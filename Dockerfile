FROM alpine:3.9 as prep

ENV BUILD_VERSION=5.01.9674

RUN apk add --no-cache git

RUN git clone --recurse-submodules --depth 1 --single-branch -b ${BUILD_VERSION} https://github.com/SoftEtherVPN/SoftEtherVPN.git /usr/local/src/SoftEtherVPN

FROM debian:10 as build

RUN apt-get update \
    && apt -y install cmake gcc g++ libncurses5-dev libreadline-dev libssl-dev make zlib1g-dev \
    file \
    zip

COPY --from=prep /usr/local/src /usr/local/src

RUN cd /usr/local/src/SoftEtherVPN \
    && sed 's/StrCmpi(region, "JP") == 0 || StrCmpi(region, "CN") == 0/false/' -i src/Cedar/Server.c \
    && ./configure \
    && make -C tmp \
    && make -C tmp package
RUN mkdir -p /tmp/softether-pkgs \
    && cp /usr/local/src/SoftEtherVPN/build/softether-*.deb /tmp/softether-pkgs

FROM debian:10-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libncurses6 \
    libreadline7 \
    libssl1.1 \
    iptables \
    zlib1g

COPY --from=build /tmp/softether-pkgs /tmp/softether-pkgs

RUN dpkg -i /tmp/softether-pkgs/*.deb

ENTRYPOINT [ "/usr/local/libexec/softether/vpnserver/vpnserver" ]

CMD [ "start", "--foreground" ]
