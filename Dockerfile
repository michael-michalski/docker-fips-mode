FROM alpine:3.9

RUN apk update \
 && apk upgrade \
 && apk add --update curl gcc g++ make autoconf ncurses-dev perl coreutils gnupg linux-headers zlib-dev

ENV ERLANG_VERSION=21.1.3 \
    ELIXIR_VERSION="v1.7.2" \
    OPENSSL_FIPS_VER=2.0.16 \
    OPENSSL_VER=1.0.2o \
    LANG=en_US.UTF-8

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

WORKDIR /tmp/erlang-build

RUN curl -fSL -o OTP-$ERLANG_VERSION.tar.gz https://github.com/erlang/otp/archive/OTP-$ERLANG_VERSION.tar.gz \
     && tar --strip-components=1 -zxf OTP-$ERLANG_VERSION.tar.gz \
     && rm OTP-$ERLANG_VERSION.tar.gz \
     && ./otp_build autoconf && \
         export ERL_TOP=/tmp/erlang-build && \
         export PATH=$ERL_TOP/bin:$PATH && \
         export CPPFlAGS="-D_BSD_SOURCE $CPPFLAGS" && \
         ./configure --prefix=/usr \
         --sysconfdir=/etc \
         --mandir=/usr/share/man \
         --infodir=/usr/share/info \
         --without-javac \
         --without-wx \
         --without-debugger \
         --without-observer \
         --without-jinterface \
         --without-cosEvent\
         --without-cosEventDomain \
         --without-cosFileTransfer \
         --without-cosNotification \
         --without-cosProperty \
         --without-cosTime \
         --without-cosTransactions \
         --without-et \
         --without-gs \
         --without-ic \
         --without-megaco \
         --without-orber \
         --without-percept \
         --without-typer \
         --enable-threads \
         --enable-shared-zlib \
         --enable-ssl=dynamic-ssl-lib \
         --enable-fips \
     && make -j7 && make install

 ## Elixir
 WORKDIR /tmp/elixir-build

 RUN set -xe \
     && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
     && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
     && tar --strip-components=1 -zxf elixir-src.tar.gz \
     && rm elixir-src.tar.gz \
     && make

FROM alpine:3.9

ENV LANG=en_US.UTF-8

COPY --from=0 /tmp/openssl-fips-build /tmp/openssl-fips-build
COPY --from=0 /tmp/openssl-build /tmp/openssl-build
COPY --from=0 /tmp/erlang-build /tmp/erlang-build
COPY --from=0 /tmp/elixir-build /tmp/elixir-build

RUN apk --no-cache update \
    && apk --no-cache upgrade \
    && apk --no-cache add make ncurses-libs perl binutils

#RUN cd /tmp/openssl-fips-build && make install

RUN cd /tmp/openssl-build && make install_sw

RUN cd /tmp/erlang-build && export ERL_TOP=/tmp/erlang-build && make install

RUN cd /tmp/elixir-build && make install

RUN rm -rf /tmp/erlang-build \
  && rm -rf /tmp/elixir-build \
  && rm -rf /tmp/openssl-fips-build \
  && rm -rf /tmp/openssl-build

RUN apk --no-cache del perl binutils