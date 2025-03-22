#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="QuartiX-v2"

# GKI Version
GKI_VERSION="android12-5.10"

# Build variables
export TZ="Asia/Makassar"
export KBUILD_BUILD_USER="eraselk"
export KBUILD_BUILD_HOST="gacorprjkt"
export KBUILD_BUILD_TIMESTAMP=$(date)
BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y%m%d-%H%M")

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

# AOSP Clang
USE_AOSP_CLANG="false"
AOSP_CLANG_SOURCE="r547379" # Should be version number or direct link to clang tarball

# Custom clang
USE_CUSTOM_CLANG="true"
CUSTOM_CLANG_SOURCE="https://www.kernel.org/pub//tools/llvm/files/llvm-20.1.1-x86_64.tar.gz"
CUSTOM_CLANG_BRANCH=""

# Note: KVER and VARIANT are placeholder and they will be changed in the build.sh script.
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT.zip"
