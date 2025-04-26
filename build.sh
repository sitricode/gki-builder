#!/usr/bin/env bash
set -e

workdir=$(pwd)
exec > >(tee $workdir/build.log) 2>&1

# Import config and functions
source $workdir/config.sh
source $workdir/functions.sh

# Set up timezone
sudo timedatectl set-timezone $TIMEZONE

cd $workdir
# Clone kernel patches
WILDPLUS_PATCHES=https://github.com/WildPlusKernel/kernel_patches
log "Cloning kernel patches from $(simplify_gh_url "$WILDPLUS_PATCHES")"
git clone -q --depth=1 $WILDPLUS_PATCHES wildplus_patches

# Clone kernel source
log "Cloning kernel source from $(simplify_gh_url "$KERNEL_REPO")"
git clone -q --depth=1 $KERNEL_REPO -b $KERNEL_BRANCH common

cd $workdir/common
LINUX_VERSION=$(make kernelversion)
DEFCONFIG_FILE=$(find $workdir/common/arch/arm64/configs -name "$KERNEL_DEFCONFIG")

# Set KernelSU variant
log "Setting KernelSU variant..."
declare -A KSU_VARIANTS=(
    ["Official"]="KSU"
    ["Next"]="KSUN"
    ["Suki"]="SUKISU"
)
VARIANT="${KSU_VARIANTS[$KSU]:-NKSU}"

# Append SUSFS to $VARIANT
[[ $USE_KSU_SUSFS == "true" ]] && VARIANT+="xSUSFS"

# Replace Placeholder in zip name
ZIP_NAME=${ZIP_NAME//KVER/$LINUX_VERSION}
ZIP_NAME=${ZIP_NAME//VARIANT/$VARIANT}

# Download Clang
cd $workdir
CLANG_PATH="$workdir/clang"

log "🔽 Downloading Clang..."
mkdir -p "$CLANG_PATH"
wget -qO clang-tarball "$CLANG_URL" || error "Failed to download Clang."
tar -xf clang-tarball -C "$CLANG_PATH/" || error "Failed to extract Clang."
rm -f clang-tarball

if [[ $(find "$CLANG_PATH" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ]] &&
    [[ $(find "$CLANG_PATH" -mindepth 1 -maxdepth 1 -type f | wc -l) -eq 0 ]]; then
    single_dir=$(find "$CLANG_PATH" -mindepth 1 -maxdepth 1 -type d)
    mv "$single_dir"/* "$CLANG_PATH"/
    rm -rf "$single_dir"
fi

export PATH="$CLANG_PATH/bin:$PATH"

# Clone GCC
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-gnu-9.3 $workdir/gcc
export PATH="$workdir/gcc/bin:$PATH"

# Extract clang version
COMPILER_STRING=$(clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')

# Apply LineageOS maphide patch (thanks to @backslashxx and @WildPlusKernel)
cd $workdir/common
log "Patching LineageOS maphide patch..."
if ! patch -p1 <$workdir/wildplus_patches/69_hide_stuff.patch; then
    log "Patch rejected. Reverting patch..."
    mv -f fs/proc/task_mmu.c.orig fs/proc/task_mmu.c
    mv -f fs/proc/base.c.orig fs/proc/base.c
fi

## KernelSU setup
if [[ $KSU != "None" ]]; then
    for ksupath in "drivers/staging/kernelsu" "drivers/kernelsu" "KernelSU"; do
        if [[ -d $ksupath ]]; then
            log "KernelSU driver found in $ksupath, Removing..."
            parent_dir="$(dirname $ksupath)"

            [[ -f "$parent_dir/Kconfig" ]] && sed -i '/kernelsu/d' "$parent_dir/Kconfig"
            [[ -f "$parent_dir/Makefile" ]] && sed -i '/kernelsu/d' "$parent_dir/Makefile"

            rm -rf $ksupath
        fi
    done
fi

# Install KernelSU driver
cd $workdir
if [[ $KSU != "None" ]]; then
    log "Installing KernelSU..."

    case "$KSU" in
    "Official") install_ksu tiann/KernelSU ;;
    "Next") install_ksu rifsxd/KernelSU-Next $([[ $USE_KSU_SUSFS == true ]] && echo next-susfs) ;;
    "Suki") install_ksu ShirkNeko/SukiSU-Ultra $([[ $USE_KSU_SUSFS == true ]] && echo susfs-dev) ;;
    *) error "Invalid KSU value: $KSU" ;;
    esac
fi

# Enable KPM for 🤓SU
if [[ $KSU == "Suki" ]]; then
    config --enable CONFIG_KPM
fi

# SUSFS for KSU setup
if [[ $USE_KSU_SUSFS == "true" ]]; then
    log "Cloning susfs4ksu..."
    git clone -q --depth=1 https://gitlab.com/simonpunk/susfs4ksu -b gki-$GKI_VERSION $workdir/susfs4ksu
    SUSFS_PATCHES="$workdir/susfs4ksu/kernel_patches"

    # Copy susfs files (Kernel Side)
    log "Copying susfs files..."
    cd $workdir/common
    cp $SUSFS_PATCHES/include/linux/* ./include/linux/
    cp $SUSFS_PATCHES/fs/* ./fs/
    SUSFS_VERSION=$(grep -E '^#define SUSFS_VERSION' ./include/linux/susfs.h | cut -d' ' -f3 | sed 's/"//g')

    # Apply kernel-side susfs patch
    log "Patching kernel-side susfs patch"
    patch -p1 <"$SUSFS_PATCHES/50_add_susfs_in_gki-$GKI_VERSION.patch"

    # Apply patch to KernelSU (KSU Side)
    if [[ $KSU == "Official" ]]; then
        cd ../KernelSU
        log "Applying KernelSU-side susfs patch"
        patch -p1 <$SUSFS_PATCHES/KernelSU/10_enable_susfs_for_ksu.patch
    fi
fi

cd $workdir/common
# Remove unnecessary code from scripts/setlocalversion
sed -i 's/-dirty//' scripts/setlocalversion
sed -i 's/echo "+"/# echo "+"/g' scripts/setlocalversion

# get latest commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

# Set localversion
config --set-str LOCALVERSION "-$KERNEL_NAME/$COMMIT_HASH"

# Needed variables before we build the kernel
export KBUILD_BUILD_USER="$USER"
export KBUILD_BUILD_HOST="$HOST"
export KBUILD_BUILD_TIMESTAMP=$(date)
if [[ $STATUS == "BETA" ]]; then
    BUILD_DATE=$(date -d "$KBUILD_BUILD_TIMESTAMP" +"%Y%m%d-%H%M")
fi

text=$(
    cat <<EOF
*=== $KERNEL_NAME CI ===*
🐧 *Linux Version*: \`$LINUX_VERSION\`
🤔 *Build Status*: \`$STATUS\`
📅 *Build Date*: \`$KBUILD_BUILD_TIMESTAMP\`
🔥 *KSU*: \`${KSU}$([[ $KSU != "None" ]] && echo " | $KSU_VERSION")\`
ඞ *SUSFS*: \`$([[ $USE_KSU_SUSFS == "true" ]] && echo "$SUSFS_VERSION" || echo "None")\`
⚙️ *Compiler*: \`$COMPILER_STRING\`
EOF
)

MESSAGE_ID=$(send_msg "$text" 2>&1 | jq -r .result.message_id)

# Define make args
MAKE_ARGS="
-j$(nproc --all)
ARCH=arm64
LLVM=1
LLVM_IAS=1
O=$workdir/out
CROSS_COMPILE=aarch64-linux-
"
KERNEL_IMAGE=$workdir/out/arch/arm64/boot/Image

# Build GKI
cd $workdir/common

set +e
log "Generating config..."
make $MAKE_ARGS $KERNEL_DEFCONFIG

# Upload config file
if [[ $GENERATE_DEFCONFIG == "true" ]]; then
    log "Uploading defconfig..."
    upload_file $workdir/out/.config
    exit 0
fi

# Build the actual kernel
log "Building kernel..."
make $MAKE_ARGS Image

# Build kernel modules
if [[ $BUILD_LKMS == "true" ]]; then
    log "Building kernel modules..."
    make $MAKE_ARGS modules || lkms_failed=y
fi

set -e

if [[ ! -f $KERNEL_IMAGE || $lkms_failed == "y" ]]; then
    error "Build Failed!"
fi

## Post-compiling stuff
cd $workdir

mkdir -p artifacts

# Clone AnyKernel
log "Cloning anykernel from $(simplify_gh_url "$ANYKERNEL_REPO")"
git clone -q --depth=1 $ANYKERNEL_REPO -b $ANYKERNEL_BRANCH anykernel

# Set kernel string in anykernel
if [[ $STATUS == "BETA" ]]; then
    sed -i \
        "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${LINUX_VERSION} (${BUILD_DATE}) ${VARIANT}/g" \
        $workdir/anykernel/anykernel.sh
else
    sed -i \
        "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${LINUX_VERSION} ${VARIANT}/g" \
        $workdir/anykernel/anykernel.sh
fi

# Patch the kernel Image for 🤓SU
if [[ $KSU == "Suki" ]]; then
    mkdir suki && cd suki
    wget -O patch_linux https://github.com/ShirkNeko/SukiSU_KernelPatch_patch/releases/download/0.11-beta/patch_linux
    chmod a+x patch_linux
    cp $KERNEL_IMAGE ./Image
    sudo ./patch_linux 2>&1
    mv oImage Image
    KERNEL_IMAGE=$(pwd)/Image
    cd -
fi

# Zipping
cd anykernel
log "Zipping anykernel..."
cp $KERNEL_IMAGE .
zip -r9 $workdir/artifacts/$ZIP_NAME ./*
cd ..

if [[ $BUILD_BOOTIMG == "true" ]]; then
    # Clone tools
    AOSP_MIRROR=https://android.googlesource.com
    BRANCH=main-kernel-build-2024
    log "Cloning build tools..."
    git clone -q --depth=1 $AOSP_MIRROR/kernel/prebuilts/build-tools -b $BRANCH build-tools
    log "Cloning mkbootimg..."
    git clone -q --depth=1 $AOSP_MIRROR/platform/system/tools/mkbootimg -b $BRANCH mkbootimg

    # Variables
    AVBTOOL=$workdir/build-tools/linux-x86/bin/avbtool
    MKBOOTIMG=$workdir/mkbootimg/mkbootimg.py
    UNPACK_BOOTIMG=$workdir/mkbootimg/unpack_bootimg.py
    BOOT_SIGN_KEY_PATH=$workdir/key/verifiedboot.pem
    BOOTIMG_NAME="${ZIP_NAME%.zip}-boot-dummy.img"
    # Note: dummy is placeholder that would be replace the Image format later

    # Function
    generate_bootimg() {
        local kernel="$1"
        local output="$2"

        # Create boot image
        log "Creating $output"
        $MKBOOTIMG --header_version 4 \
            --kernel "$kernel" \
            --output "$output" \
            --ramdisk out/ramdisk \
            --os_version 12.0.0 \
            --os_patch_level $(date +"%Y-%m")

        sleep 1

        # Sign the boot image
        log "Signing $output"
        $AVBTOOL add_hash_footer \
            --partition_name boot \
            --partition_size $((64 * 1024 * 1024)) \
            --image "$output" \
            --algorithm SHA256_RSA2048 \
            --key $BOOT_SIGN_KEY_PATH
    }

    # Prepare boot image
    mkdir -p bootimg && cd bootimg
    cp $KERNEL_IMAGE .
    gzip -n -f -9 -c Image >Image.gz
    lz4 -l -12 --favor-decSpeed Image Image.lz4

    # Download and unpack prebuilt GKI
    log "Downloading prebuilt GKI..."
    wget -qO gki.zip https://dl.google.com/android/gki/gki-certified-boot-android12-5.10-2023-01_r1.zip
    log "Unpacking prebuilt GKI..."
    unzip -q gki.zip && rm gki.zip
    $UNPACK_BOOTIMG --boot_img=boot-5.10.img
    rm boot-5.10.img

    # Generate and sign boot images in multiple formats (raw, lz4, gz)
    for format in raw lz4 gz; do
        # Initialize kernel variable
        kernel="./Image"
        [[ $format != "raw" ]] && kernel+=".$format"

        log "Using kernel: $kernel"
        output="${BOOTIMG_NAME/dummy/$format}"
        generate_bootimg "$kernel" "$output"

        log "Moving $output to artifacts directory"
        mv -f "$output" $workdir/artifacts/
    done
    cd $workdir
fi

if [[ $BUILD_LKMS == "true" ]]; then
    mkdir lkm && cd lkm
    find "$workdir/out" -type f -name "*.ko" -exec cp {} . \; || true
    [[ -n "$(ls -A ./*.ko 2>/dev/null)" ]] && zip -r9 "$workdir/artifacts/lkm-$LINUX_VERSION.zip" ./*.ko || log "No LKMs found."
    cd ..
fi

echo "BASE_NAME=$KERNEL_NAME-$VARIANT" >>$GITHUB_ENV

if [[ $LAST_BUILD == "true" ]]; then
    (
        echo "LINUX_VERSION=$LINUX_VERSION"
        echo "SUSFS_VERSION=$(curl -s https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-${GKI_VERSION}/kernel_patches/include/linux/susfs.h | grep -E '^#define SUSFS_VERSION' | cut -d' ' -f3 | sed 's/"//g')"
        echo "KSU_OFC_VERSION=$(gh api repos/tiann/KernelSU/tags --jq '.[0].name')"
        echo "KSU_NEXT_VERSION=$(gh api repos/rifsxd/KernelSU-Next/tags --jq '.[0].name')"
        echo "SUKISU_VERSION=$(gh api repos/ShirkNeko/SukiSU-Ultra/tags --jq '.[0].name')"
        echo "KERNEL_NAME=$KERNEL_NAME"
        echo "GKI_VERSION=$GKI_VERSION"
        echo "RELEASE_REPO=$(simplify_gh_url "$GKI_RELEASES_REPO")"
    ) >>$workdir/artifacts/info.txt
fi

if [[ $STATUS == "BETA" ]]; then
    reply_msg "$MESSAGE_ID" "✅ Build Succeeded
📦 Download: [here]($NIGHTLY_LINK)"
else
    reply_msg "$MESSAGE_ID" "✅ Build Succeeded"
fi

exit 0
