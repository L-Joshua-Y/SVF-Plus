#!/usr/bin/env bash

set -e

sys_os="$(uname -s)"
arch="$(uname -m)"

if [[ "$sys_os" != "Linux" ]]; then
    echo "This script only supports Linux platform!"
    exit 1
fi

if [[ "$arch" != "x86_64" ]]; then
    echo "This script only supports x86_64 platform!"
    exit 1
fi

build_type="Release"
rebuild_flag=0
jobs=1
if [ $# -gt 0 ]; then
    for arg in "${@:1}"; do
        if [ "$arg" = "-r" ] || [ "$arg" = "-re" ]; then
            rebuild_flag=1
        fi
        if [[ $arg =~ ^[Dd]ebug$ ]]; then
            build_type="Debug"
        fi
        if [[ "$arg" = "-j"* ]]; then
            length=$(echo -n $arg | wc -c)
            if [ $length -lt 3 ]; then
                jobs=$(nproc)
            else
                jobs=$((${arg:2}))
            fi
        fi
    done
fi

support_dir="$SUPPORT_DIR"
if [ ! -d "$support_dir" ]; then
    support_dir="$HOME/support"
fi
if [ ! -d "$support_dir" ]; then
    echo "Failed to find support directory!"
    exit 1
fi

LLVM_DIR_NAME="llvm-14.0.0.obj"
Z3_DIR_NAME="z3.obj"

llvm_dir="$support_dir/$LLVM_DIR_NAME"
z3_dir="$support_dir/$Z3_DIR_NAME"

if [ ! -d "$llvm_dir" ]; then
    echo "Failed to find LLVM directory under $support_dir!"
    exit 1
fi
if [ ! -d "$z3_dir" ]; then
    echo "Failed to find Z3 directory under $support_dir!"
    exit 1
fi
if [ ! -d "$llvm_dir/bin" ]; then
    echo "Failed to find binaries under $llvm_dir!"
    exit 1
fi

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
svf_home="${script_dir}"

build_dir="${build_type}-build"

export PATH=$llvm_dir/bin:$PATH
export LLVM_DIR=$llvm_dir
export Z3_DIR=$z3_dir

echo "Building Mode: $build_type"
echo "Parallel Jobs: $jobs"
if [ "$rebuild_flag" = "1" ]; then
    echo "Rebuild Flag: Yes"
    rm -rf "$build_dir"
    cmake -D CMAKE_BUILD_TYPE:STRING="${build_type}" \
        -DSVF_ENABLE_ASSERTIONS:BOOL=true            \
        -DSVF_SANITIZE="${SVF_SANITIZER}"            \
        -DBUILD_SHARED_LIBS=off                      \
        -S "${svf_home}" -B "${build_dir}"
else
    echo "Rebuild Flag: No"
    if [ ! -d "$build_dir" ]; then
        cmake -D CMAKE_BUILD_TYPE:STRING="${build_type}" \
            -DSVF_ENABLE_ASSERTIONS:BOOL=true            \
            -DSVF_SANITIZE="${SVF_SANITIZER}"            \
            -DBUILD_SHARED_LIBS=off                      \
            -S "${svf_home}" -B "${build_dir}"
    fi
fi

## build
cmake --build "${build_dir}" -j $jobs