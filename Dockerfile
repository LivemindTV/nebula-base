FROM python:3.11-bullseye AS base

RUN apt-get update && apt-get -y upgrade && apt-get install -yqq \
    curl \
    wget

RUN pip install --upgrade pip \
  && pip install poetry \
  && poetry config virtualenvs.create false 

#
# Build base
#

FROM base AS build

RUN apt-get install -yqq \
  apt-utils \
  autoconf \
  automake \
  build-essential \
  cmake \
  g++ \
  git \
  intltool \
  libexpat1-dev \
  libtool \
  liburiparser-dev \
  meson \
  nasm \
  ninja-build \
  pkg-config \
  swig \
  uuid-dev \
  wget \
  yasm 

#
# BMX
#

FROM build AS bmx

RUN mkdir /src
WORKDIR /src

RUN git clone https://github.com/Limecraft/ebu-libmxf
RUN git clone https://github.com/Limecraft/ebu-libmxfpp
RUN git clone https://github.com/Limecraft/ebu-bmx

WORKDIR /src/ebu-libmxf
RUN ./autogen.sh && ./configure && make && make install && /sbin/ldconfig

WORKDIR /src/ebu-libmxfpp
RUN ./autogen.sh && ./configure && make && make install && /sbin/ldconfig

WORKDIR /src/ebu-bmx
RUN ./autogen.sh && ./configure && make && make install && /sbin/ldconfig

#
# FFMPEG
#

FROM build AS ffmpeg

ENV FFMPEG_VERSION 6.0
ENV MLT_VERSION 7.16.0
ENV LD_LIBRARY_PATH /usr/local/lib

WORKDIR /src

# FFMPEG

RUN \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz \
  && tar -xzf ffmpeg-${FFMPEG_VERSION}.tar.gz \
  && rm ffmpeg-${FFMPEG_VERSION}.tar.gz \
  && mv ffmpeg-${FFMPEG_VERSION} ffmpeg

# MLT

RUN \
  wget https://github.com/mltframework/mlt/archive/refs/tags/v${MLT_VERSION}.tar.gz \
  && tar -xzf v7.16.0.tar.gz \
  && rm v${MLT_VERSION}.tar.gz \
  && mv mlt-${MLT_VERSION} mlt

# Build ffmpeg

WORKDIR /src/ffmpeg

RUN apt-get install -yqq \
  libgcrypt20-dev \
  libgnutls-openssl-dev \
  libx264-dev \
  libmp3lame-dev \
  libsox-dev \
  libtheora-dev \
  libvorbis-dev \
  libvpx-dev 

RUN ./configure \
  --prefix=/usr/local \
  --disable-doc \
  --enable-gpl \
  --enable-version3 \
  --enable-shared \
  --enable-debug \
  --enable-pthreads \
  --enable-libmp3lame \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-gnutls \
  --extra-version=NEBULA \
  --enable-runtime-cpudetect && make -j16 && make install

# Build MLT

WORKDIR /src/mlt/build

RUN apt-get install -yqq \
  libgavl-dev \
  libsamplerate0-dev \
  libxml2-dev \
  ladspa-sdk \
  libjack-dev \
  libsoup2.4-dev \
  libexif-dev \
  xutils-dev \
  libegl1-mesa-dev \
  libeigen3-dev \
  libfftw3-dev \
  libvdpau-dev \
  librtaudio-dev \
  libsamplerate-dev \
  python3-dev

RUN cmake --enable-gpl -D SWIG_PYTHON=ON ..
RUN cmake --build .
RUN cmake --install . --prefix /usr/local

#
# Final image
#

FROM base

ENV PYTHONUNBUFFERED=1

COPY --from=bmx /usr/local/lib/lib* /usr/local/lib/
COPY --from=bmx /usr/local/bin/* /usr/local/bin/

# Install runtime dependencies
# Build essentials are needed for building some python packages

RUN apt-get install -yqq \
  amb-plugins \
  build-essential \
  cifs-utils \
  curl \
  libexif12 \
  libexpat1 \
  libgcrypt20 \
  libgnutls-openssl27 \
  libmp3lame0 \
  librtaudio6 \
  libsamplerate0 \
  libsox3 \
  libtheora0 \
  liburiparser1 \
  libvorbis0a \
  libvpx6 \
  libx264-160 \
  libxml2 \
  lsp-plugins-ladspa \
  mediainfo \
  uuid \
  zlib1g-dev

#
# Copy built files
#

COPY --from=ffmpeg /usr/local/ /usr/local/
RUN cp /usr/local/lib/python3/dist-packages/mlt7.py /usr/local/lib/python3.11/site-packages/mlt.py
RUN cp /usr/local/lib/python3/dist-packages/_mlt7.so /usr/local/lib/python3.11/site-packages/_mlt7.so

RUN ldconfig
