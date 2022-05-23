#!/usr/bin/env bash
  
# Main Declaration
function env() {
export KERNEL_NAME=KERNEL
KERNEL_ROOTDIR=$CIRRUS_WORKING_DIR/KERNEL
DEVICE_DEFCONFIG=vendor/juice_defconfig
CLANG_ROOTDIR=$CIRRUS_WORKING_DIR/CLANG
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
IMGS=$KERNEL_ROOTDIR/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
export KBUILD_BUILD_USER=$BUILD_USER
export KBUILD_BUILD_HOST=$BUILD_HOST
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
export BOT_MSG_URL="https://api.telegram.org/$TG_TOKEN/sendMessage"
export BOT_MSG_URL2="https://api.telegram.org/$TG_TOKEN"
}
# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}
tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}
# Compile
compile(){
cd ${KERNEL_ROOTDIR}
    make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
    make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMGS" ]; then
	finerr
   fi
   git clone --depth=1 https://github.com/fadlyas07/anykernel-3 $CIRRUS_WORKING_DIR/AnyKernel
   cp $IMGS $CIRRUS_WORKING_DIR/AnyKernel
}
# Push kernel to channel
function push() {
    cd $CIRRUS_WORKING_DIR/AnyKernel
    zip -r9 $KERNEL_NAME-$DEVICE_CODENAME-${DATE}.zip *
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$KERNEL_NAME
==========================
👤 Owner: ryujin-xd
🏚️ Linux version: $KERNEL_VERSION
🌿 Branch: $BRANCH
🎁 Top commit: $LATEST_COMMIT
👩‍💻 Commit author: $COMMIT_BY
🐧 UTS version: $UTS_VERSION
💡 Compiler: $TOOLCHAIN_VERSION
==========================
Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
}
# Fin Error
function finerr() {
    curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
	    -d "disable_web_page_preview=true" \
	    -d "parse_mode=html" \
        -d text="==============================%0A<b>    Building Kernel CLANG Failed [❌]</b>%0A==============================" \
    curl -s -X POST "$BOT_MSG_URL2/sendSticker" \
        -d sticker="CAACAgIAAx0CXjGT1gACDRRhYsUKSwZJQFzmR6eKz2aP30iKqQACPgADr8ZRGiaKo_SrpcJQIQQ" \
        -d chat_id="$TG_CHAT_ID"
    exit 1
}

function info() {
cd $KERNEL_ROOTDIR
KERNEL_VERSION=$(cat $KERNEL_ROOTDIR/out/.config | grep Linux/arm64 | cut -d " " -f3)
UTS_VERSION=$(cat $KERNEL_ROOTDIR/out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)
TOOLCHAIN_VERSION=$(cat $KERNEL_ROOTDIR/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
TRIGGER_SHA="$(git rev-parse HEAD)"
LATEST_COMMIT="$(git log --pretty=format:'%s' -1)"
COMMIT_BY="$(git log --pretty=format:'by %an' -1)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

}

env
check
compile
END=$(date +"%s")
DIFF=$(($END - $START))
info
push
