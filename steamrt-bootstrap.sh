#!/bin/bash

# Expect to be setting up a container or chroot
if [[ $(stat -c %d:%i /) != $(stat -c %d:%i /proc/1/root/.) ]]; then
  echo "Running in chroot environment. Continuing..."
elif [[ -f /.dockerenv ]]; then
  echo "Running in docker environment. Continuing..."
else
  echo "Script must be running in a chroot environment. Exiting..."
  exit 1
fi

set -xe

apt-get install -y gcc-5 g++-5 g++-5-multilib flex bison libosmesa6-dev libpcap-dev \
                   libhal-dev libsane-dev libv4l-dev libgphoto2-2-dev libcapi20-dev \
                   libgsm1-dev libmpg123-dev libvulkan-dev libxslt1-dev nasm yasm ccache
update-alternatives --install "$(command -v gcc)" gcc "$(command -v gcc-5)" 50
update-alternatives --set gcc "$(command -v gcc-5)"
update-alternatives --install "$(command -v g++)" g++ "$(command -v g++-5)" 50
update-alternatives --set g++ "$(command -v g++-5)"
update-alternatives --install "$(command -v cpp)" cpp-bin "$(command -v cpp-5)" 50
update-alternatives --set cpp-bin "$(command -v cpp-5)"
# Gallium Nine
#
# dri3proto, presentproto, libxshmfence, libdrm>=2.4.56 missing deps for mesa
# mesa>=10.5 for gallium nine, 10.4 has issues with the available llvm
# set the build toolchain explicitely to match the arch
# set LDFLAGS=-L/usr/local/lib for builds needing the newer libs
BUILD_CHAIN="$(basename "$(ls -1 /usr/bin/*-linux-gnu* | head -n 1)" | grep -o '.*-linux-gnu')" \
&& apt-get install --force-yes -y libegl1-mesa-dev libpciaccess-dev automake \
&& cd /tmp \
&& wget https://www.x.org/archive/individual/proto/dri3proto-1.0.tar.bz2 \
&& tar xf dri3proto-1.0.tar.bz2 \
&& cd dri3proto-1.0 \
&& ./configure --build="${BUILD_CHAIN}" && make install \
&& cd .. \
&& wget https://www.x.org/archive/individual/proto/presentproto-1.1.tar.bz2 \
&& tar xf presentproto-1.1.tar.bz2 \
&& cd presentproto-1.1 \
&& ./configure --build="${BUILD_CHAIN}" && make install \
&& cd .. \
&& wget http://xorg.freedesktop.org/archive/individual/lib/libxshmfence-1.1.tar.bz2 \
&& tar xf libxshmfence-1.1.tar.bz2 \
&& cd libxshmfence-1.1 \
&& ./configure --build="${BUILD_CHAIN}" && make -j4 && make install \
&& cd .. \
&& wget https://dri.freedesktop.org/libdrm/libdrm-2.4.56.tar.bz2 \
&& tar xf libdrm-2.4.56.tar.bz2 \
&& cd libdrm-2.4.56 \
&& ./configure --build="${BUILD_CHAIN}" && make -j4 && make install \
&& cd .. \
&& ln -s /usr/bin/llvm-config-3.6 /usr/bin/llvm-config \
&& wget https://mesa.freedesktop.org/archive/older-versions/10.x/10.5.9/mesa-10.5.9.tar.xz \
&& tar xf mesa-10.5.9.tar.xz \
&& cd mesa-10.5.9 \
&& autoreconf -vfi && ./configure --build="${BUILD_CHAIN}" --enable-nine && make -j4 && make install \
&& cd .. \
&& rm -rf *
