#!/bin/bash
#
#  Copyright (C) 2017 Intel Corporation
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

set -e
if [ -n "$DEBUG" ] ; then
	set -x
fi


SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(dirname $(realpath -s $0))"
REPO_URL=${REPO_URL:-https://download.clearlinux.org/current/x86_64/os/}



IMAGE_BUILDER_SH="image_buidler.sh"
if ! type ${IMAGE_BUILDER_SH} >/dev/null 2>&1; then
	IMAGE_BUILDER_SH="${SCRIPT_DIR}/image_builder.sh"
fi


BUILD="$1"
ROOTFS_DIR="$(pwd)/rootfs"

die()
{
	msg="$*"
	echo "ERROR: ${msg}" >&2
	exit 1
}

info()
{
	msg="$*"
	echo "INFO: ${msg}" >&2
}

usage()
{
	cat <<EOT
Usage: ${SCRIPT_NAME} rootfs|kernel|image
rootfs : Build a rootfs based on Clear Linux packages
kernel : Build a kernel for clear containers
image  : Build a Clear Containers image based on rootfs directory
EOT
	exit 1
} 

check_program(){
	type "$1" >/dev/null 2>&1
}

generate_dnf_config()
{
	cat > "${DNF_CONF}" << EOF
[main]
cachedir=/var/cache/dnf/clear/
keepcache=0
debuglevel=2
logfile=/var/log/dnf.log
exactarch=1
obsoletes=1
gpgcheck=0
plugins=0
installonly_limit=3
#Dont use the default dnf reposdir
#this will prevent to use host repositories
reposdir=/root/mash

[clear]
name=Clear
failovermethod=priority
baseurl=${REPO_URL}
enabled=1
gpgcheck=0
EOF
}

build_rootfs()
{
	if [ ! -f "${DNF_CONF}" ]; then
		DNF_CONF="/etc/dnf/clear-dnf.conf"
		generate_dnf_config
	fi
	mkdir -p "${ROOTFS_DIR}"
	if check_program "dnf"; then
		DNF="dnf"
	elif check_program "yum" ; then
		DNF="yum"
	else
		die "neither yum nor dnf is installed"
	fi
	DNF="$DNF --config=$DNF_CONF -y --installroot=${ROOTFS_DIR} --noplugins"
	$DNF install systemd hyperstart cc-oci-runtime-extras coreutils-bin systemd-bootchart iptables-bin
	[ -n "${ROOTFS_DIR}" ]  && rm -r "${ROOTFS_DIR}/var/cache/dnf"
}

build_kernel()
{
	pushd linux
	make -j"$(nproc)"
	popd
	cp linux/vmlinux vmlinux.container
}

check_root()
{
	if [ "$(id -u)" != "0" ]; then
		echo "Root is needed"
		exit 1
	fi
}

# main
[ -n "${BUILD}" ] || usage


case "$BUILD" in
        rootfs)
			check_root
			build_rootfs
            ;;
         
        kernel)
			build_kernel
            ;;
         
        image)
			check_root
			$IMAGE_BUILDER_SH "$(pwd)/rootfs"
            ;;
        *)
			usage
esac
