#!/usr/bin/env bash
 
# Kernel Sources!
git clone --depth=1 https://github.com/ryujin-xd/android_kernel_xiaomi_ginkgo-2 -b 11.0 $CIRRUS_WORKING_DIR/KERNEL

# Tool Chain
# Proton Clang ---
git clone --depth=1 https://github.com/kdrag0n/proton-clang $CIRRUS_WORKING_DIR/PROTON-CLANG
# Azure Clang ---
git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang $CIRRUS_WORKING_DIR/AZURE-CLANG
 
