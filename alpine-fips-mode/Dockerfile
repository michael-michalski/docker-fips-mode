FROM alpine:3.9

ARG OPENSSL_FIPS_VER=2.0.16
ARG OPENSSL_VER=1.0.2o

RUN apk update \
    && cd /root \
    && apk upgrade \
    && apk add --update curl gcc gzip tar libc-dev ca-certificates perl make coreutils gnupg linux-headers zlib-dev

WORKDIR /tmp/openssl-fips-build

RUN curl -fSL -o openssl-fips-$OPENSSL_FIPS_VER.tar.gz https://www.openssl.org/source/openssl-fips-$OPENSSL_FIPS_VER.tar.gz \
    && tar --strip-components=1 -xzf openssl-fips-$OPENSSL_FIPS_VER.tar.gz \
    && ./config \
    && make \
    && make install

WORKDIR /tmp/openssl-build
RUN curl -fSL -o openssl-$OPENSSL_VER.tar.gz https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz \
    && tar --strip-components=1  -xzf openssl-$OPENSSL_VER.tar.gz \
    && perl ./Configure linux-x86_64 --prefix=/usr \
                                     --libdir=lib \
                                     --openssldir=/etc/ssl \
                                     fips shared zlib \
                                     -DOPENSSL_NO_BUF_FREELISTS \
                                     -Wa,--noexecstack enable-ssl2 \
    && make \
    && make install_sw

FROM alpine:3.9

ENV LANG=en_US.UTF-8

COPY --from=0 /tmp/openssl-fips-build /tmp/openssl-fips-build
COPY --from=0 /tmp/openssl-build /tmp/openssl-build

RUN apk --no-cache update \
    && apk --no-cache upgrade \
    && apk --no-cache add make ncurses-libs perl binutils

RUN cd /tmp/openssl-fips-build && make install

RUN cd /tmp/openssl-build && make install_sw

RUN rm -rf /tmp/openssl-fips-build \
  && rm -rf /tmp/openssl-build

RUN apk --no-cache del perl binutils