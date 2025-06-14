#!/bin/bash
# Copyright 2022 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# This shell script uses Docker to run build-boring.sh and build-goboring.sh,
# which build goboringcrypto_linux_$GOARCH.syso according to the Security Policy.
# Currently, amd64 and arm64 are permitted.

set -e
set -o pipefail

GOARCH=${GOARCH:-$(go env GOARCH)}
echo "# Building goboringcrypto_linux_$GOARCH.syso. Set GOARCH to override." >&2

if ! which docker >/dev/null; then
	echo "# Docker not found. Inside Google, see go/installdocker." >&2
	exit 1
fi

platform=""
buildargs=""
digest=""
case "$GOARCH" in
amd64)
	platform="--platform linux/amd64"
	digest="sha256:6f63292a7444f9346bf6ec6816dd93029dae021ee00cabb564c440417519680c"
	if ! docker run --rm -t $platform ubuntu:jammy@$digest uname -m >/dev/null 2>&1; then
		echo "# Docker cannot run amd64 binaries."
		exit 1
	fi
	buildargs="--build-arg ubuntu=ubuntu:jammy@$digest"
	;;
arm64)
	platform="--platform linux/arm64/v8"
	digest="sha256:103c9bebe997b8f0f71868e30217cebffc3bce08337c6ae6c6beac31634c1546"
	if ! docker run --rm -t $platform ubuntu:jammy@$digest uname -m >/dev/null 2>&1; then
		echo "# Docker cannot run arm64 binaries. Try:"
		echo "	sudo apt-get install qemu binfmt-support qemu-user-static"
		echo "	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
		echo "	docker run --rm -t $platform ubuntu:jammy@$digest uname -m"
		exit 1
	fi
	buildargs="--build-arg ubuntu=ubuntu:jammy@$digest"
	;;
*)
	echo unknown GOARCH $GOARCH >&2
	exit 2
esac

SOURCE_DATE_EPOCH=1748634593 docker build $platform $buildargs --build-arg GOARCH=$GOARCH -t goboring:$GOARCH .
id=$(docker create $platform goboring:$GOARCH)
docker cp $id:/boring/godriver/goboringcrypto_linux_$GOARCH.syso ./syso
docker rm $id
ls -l ./syso/goboringcrypto_linux_$GOARCH.syso
