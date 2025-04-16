#!/usr/bin/env bash

# slim llvm
SL_REPO="https://www.kernel.org/pub/tools/llvm/files/"
# rv clang
RC_REPO="https://api.github.com/repos/Rv-Project/RvClang/releases/latest"
# aosp clang
AOSP_REPO="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master"
AOSP_ARCHIVE="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master"

case "$1" in
"slim")
    curl -s "$SL_REPO" | grep -oP 'llvm-[\d.]+-x86_64\.tar\.xz' | sort -V | tail -n1 | sed "s|^|$SL_REPO|"
    ;;

"rv")
    curl -s "$RC_REPO" | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4
    ;;

"aosp")
    LATEST_CLANG=$(curl -s "$AOSP_REPO" | grep -oE "clang-r[0-9a-f]+" | sort -u | tail -n1)
    echo "$AOSP_ARCHIVE/$LATEST_CLANG.tar.gz"
    ;;
*)
    if [[ -z $1 ]]; then
        echo "Usage: $0 <clang-name>"
        echo "clang-name: slim, rv, aosp"
    else
        echo "Invalid clang name '$1'"
    fi
    exit 1
    ;;
esac
