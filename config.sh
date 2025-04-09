#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="QuartiX-v2"

# GKI Version
GKI_VERSION="android12-5.10"

# Build variables
USER="eraselk"
HOST="gacorprjkt"
TIMEZONE="Asia/Makassar"

# AnyKernel variables
ANYKERNEL_REPO="https://github.com/linastorvaldz/anykernel"
ANYKERNEL_BRANCH="gki"

# Kernel
KERNEL_REPO="https://github.com/linastorvaldz/kernel_new"
KERNEL_BRANCH="android12-5.10"
KERNEL_DEFCONFIG="gki_defconfig"
DEFCONFIGS_TO_MERGE=""

# Releases repository
GKI_RELEASES_REPO="https://github.com/linastorvaldz/quartix-releases"

# Clang
CLANG_URL="$(./clang.sh slim)"

# Note: KVER and VARIANT are placeholder and they will be changed in the build.sh script.
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT.zip"
