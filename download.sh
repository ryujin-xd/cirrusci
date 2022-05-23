#!/usr/bin/env bash

# Kernel Sources
git config --global user.email "ryujinxd6@gmail.com" -y && git config --global user.name "ryujin-xd"
git clone --depth=1 https://github.com/ryujin-xd/android_kernel_xiaomi_ginkgo-1 -b Q $CIRRUS_WORKING_DIR/KERNEL

git clone --depth=1 https://github.com/kdrag0n/proton-clang $CIRRUS_WORKING_DIR/CLANG
