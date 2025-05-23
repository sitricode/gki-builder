#!/usr/bin/env bash

# Kernel name
KERNEL_NAME="Mahiru-extended"

# GKI Version
GKI_VERSION="android12-5.10"

# Build variables
export TZ="Asia/Jakarta"
export KBUILD_BUILD_USER="sitri"
export KBUILD_BUILD_HOST="Qbolt"
export KBUILD_BUILD_TIMESTAMP=$(date)

# AnyKernel variables
ANYKERNEL_REPO="https://github.com/sitricode/anykernel"
ANYKERNEL_BRANCH="gki"

# Kernel
KERNEL_REPO="https://github.com/sitricode/mahiru32"
KERNEL_BRANCH="mahiru-main"
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
GKI_RELEASES_REPO="https://github.com/sitricode/mahiru32"

# AOSP Clang
USE_AOSP_CLANG="true"
AOSP_CLANG_SOURCE="r536225" # Should be version number or direct link to clang tarball

# Custom clang
USE_CUSTOM_CLANG="false"
CUSTOM_CLANG_SOURCE="https://github.com/Rv-Project/RvClang/releases/download/20.1.0/RvClang-20.1.0-bolt-pgo-full_lto.tar.gz"
CUSTOM_CLANG_BRANCH=""

# Zip name
BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y-%m-%d-%H%M")
ZIP_NAME="$KERNEL_NAME-KVER-VARIANT.zip"
# Note: KVER and VARIANT are placeholder and they will be changed in the build.sh script.
