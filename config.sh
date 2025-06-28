#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="Miharu"

# GKI Version
GKI_VERSION="android12-5.10"

# Build variables
export TZ="Asia/Jakarta"
export KBUILD_BUILD_USER="sitri"
export KBUILD_BUILD_HOST="build-host"
export KBUILD_BUILD_TIMESTAMP=$(date)

# AnyKernel variables
ANYKERNEL_REPO="https://github.com/sitricode/anykernel"
ANYKERNEL_BRANCH="gki"

# Kernel
KERNEL_REPO="https://github.com/sitricode/gki_5.10"
KERNEL_BRANCH="master"
KERNEL_DEFCONFIG="gki_defconfig"
DEFCONFIG_FILE="$workdir/common/arch/arm64/configs/$KERNEL_DEFCONFIG"

# Defconfigs would be merged in the compiling processes
DEFCONFIGS_EXAMPLE="
vendor/xiaomi.config
vendor/gold.config
"
DEFCONFIGS="
" # Leave this empty if you don't need to merge any configs

# Releases repository
GKI_RELEASES_REPO="https://github.com/sitricode/gki-release"

# AOSP Clang
USE_AOSP_CLANG="true"
AOSP_CLANG_SOURCE="r536225" # Should be version number or direct link to clang tarball

# Custom clang
USE_CUSTOM_CLANG="false"
CUSTOM_CLANG_SOURCE="https://github.com/liliumproject/clang/releases/download/20250609/lilium_clang-20250609.tar.gz"
CUSTOM_CLANG_BRANCH=""
#Clang setting
USE_THIN_LTO="false"
OPT_CC_PATCH="true"

# Zip name
BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y-%m-%d-%H%M")
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT.zip"
# Note: KVER and VARIANT are placeholder and they will be changed in the build.sh script.
