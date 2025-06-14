# Copyright 2020 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Run this using build.sh.

ARG ubuntu=ubuntu:jammy@sha256:01a3ee0b5e413cefaaffc6abe68c9c37879ae3cced56a8e088b1649e5b269eee
FROM $ubuntu

RUN mkdir /boring
WORKDIR /boring

# From stat of /etc/cloud/build.info
ENV APT_SNAPSHOT=20250530T194953Z
ENV LANG=C.UTF-8
ENV LANGUAGE=

# Following the Security Policy for FIPS 140 certificate #4953.
# https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4953.pdf
# This corresponds to boringssl.googlesource.com/boringssl tag fips-20220613.
RUN apt-get update && \
	apt-get install --no-install-recommends -y openssl ca-certificates && \
	sed "s|deb |deb [snapshot=$APT_SNAPSHOT] |" -i /etc/apt/sources.list && \
	apt-get update && \
	apt-get install --no-install-recommends -y xz-utils wget unzip ca-certificates python-is-python3 lsb-release software-properties-common gnupg make openssl libssl-dev faketime

# Install Clang.
ENV ClangV=16
RUN \
	wget https://apt.llvm.org/llvm.sh && \
	chmod +x llvm.sh && \
	./llvm.sh $ClangV

# Download, validate, unpack, build, and install Ninja.
ENV NinjaV=1.11.1
ENV NinjaH=31747ae633213f1eda3842686f83c2aa1412e0f5691d1c14dbbcc67fe7400cea
RUN \
	wget https://github.com/ninja-build/ninja/archive/refs/tags/v$NinjaV.tar.gz && \
	echo "$NinjaH v$NinjaV.tar.gz" >sha && sha256sum -c sha && \
	tar -xzf v$NinjaV.tar.gz && \
	rm v$NinjaV.tar.gz && \
	cd ninja-$NinjaV && \
	CC=clang-$ClangV CXX=clang++-$ClangV ./configure.py --bootstrap && \
	mv ninja /usr/local/bin/

# Download, validate, unpack, build, and install Cmake.
ARG GOARCH
ENV CmakeV=3.27.4
ENV CmakeHamd64=186c53121cf6ef4e48b51e88690e6ef84f268611064a42e5a2e829c3d6b2efde
ENV CmakeHarm64=45538d394bd4ef2a423fa78dff5cad16bcf437a4a6dc655e999177170632b039
RUN \
	set -x; eval CmakeH=\${CmakeH$GOARCH} && \
	case $GOARCH in amd64) arch=x86_64;; arm64) arch=aarch64;; esac && \
	wget https://github.com/Kitware/CMake/releases/download/v${CmakeV}/cmake-${CmakeV}-linux-${arch}.tar.gz && \
	echo "$CmakeH cmake-$CmakeV-linux-$arch.tar.gz" >sha && sha256sum -c sha && \
	tar -xzf cmake-$CmakeV-linux-$arch.tar.gz && \
	rm cmake-$CmakeV-linux-$arch.tar.gz && \
	cd cmake-$CmakeV-linux-$arch && \
	cp bin/* /usr/local/bin && \
	cp -r share/cmake-* /usr/local/share

# Download, validate, unpack, and install Go.
ARG GOARCH
ENV GoV=1.21.1
ENV GoHamd64=b3075ae1ce5dab85f89bc7905d1632de23ca196bd8336afd93fa97434cfa55ae
ENV GoHarm64=7da1a3936a928fd0b2602ed4f3ef535b8cd1990f1503b8d3e1acc0fa0759c967
RUN \
	eval GoH=\${GoH$GOARCH} && \
	wget https://golang.org/dl/go$GoV.linux-$GOARCH.tar.gz && \
	echo "$GoH go$GoV.linux-$GOARCH.tar.gz" >sha && sha256sum -c sha && \
	tar -C /usr/local -xzf go$GoV.linux-$GOARCH.tar.gz && \
	rm go$GoV.linux-$GOARCH.tar.gz && \
	ln -s /usr/local/go/bin/go /usr/local/bin/

# Download, validate, and unpack BoringCrypto.
ENV BoringV=a430310d6563c0734ddafca7731570dfb683dc19
ENV BoringH=2d5339b756dbf1ceb4fdc4b1c8f19e32ded055292dc57827a6592f15ca9d359f
RUN \
	wget https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-$BoringV.tar.xz && \
	echo "$BoringH boringssl-$BoringV.tar.xz" >sha && sha256sum -c sha && \
	tar xJf boringssl-$BoringV.tar.xz

# Build BoringCrypto.
ADD build-boring.sh /boring/build-boring.sh
RUN /boring/build-boring.sh

# Build Go BoringCrypto syso.
# build.sh copies it back out of the Docker image.
ADD goboringcrypto.h /boring/godriver/goboringcrypto.h
ADD build-goboring.sh /boring/build-goboring.sh
RUN /boring/build-goboring.sh

# Reproducible build check
ARG GOARCH
ENV GoBoringCryptoHamd64=12fe454ea78391f55ddc7c55519965f7d3c9372f59064cc971f1b2dc3f946af5
ENV GoBoringCryptoHarm64=71bfff4453bde67d969c7cbabc57517846ed47b2f913bb40bfa8f5f5e14e0cda
RUN \
	eval GoBoringCryptoH=\${GoBoringCryptoH$GOARCH} && \
	echo "$GoBoringCryptoH /boring/godriver/goboringcrypto_linux_$GOARCH.syso" >sha && sha256sum -c sha