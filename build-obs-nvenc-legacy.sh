#!/usr/bin/env bash
#
# ==============================================================================
# Script:       build-obs-nvenc-legacy.sh
# Description:  Automated build script for OBS Studio on Arch/Manjaro Linux
#               targeting legacy NVIDIA GPUs (GTX 900/1000 series) with 570.xx/580.xx
#               drivers requiring NVENC SDK 13.0 instead of 13.1.
# Author:       Community Contributed
# License:      MIT License
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
DEFAULT_OBS_VERSION="32.2.2"
OBS_VERSION="${1:-$DEFAULT_OBS_VERSION}"
NV_HEADERS_TAG="n13.0.19.1"
BUILD_DIR="${HOME}/.cache/obs-legacy-build"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE} OBS Studio Legacy NVENC Builder for Arch / Manjaro Linux        ${NC}"
echo -e "${BLUE} Target OBS Version: ${OBS_VERSION} | NVENC SDK: 13.0           ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Check that the script is NOT executed directly as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root/sudo directly!${NC}"
    echo "Run it as your normal user. It will prompt for sudo when necessary."
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. Install Dependencies
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[1/5] Installing required dependencies via pacman...${NC}"
sudo pacman -S --needed --noconfirm \
    base-devel git cmake \
    swig vulkan-headers \
    nlohmann-json asio websocketpp extra-cmake-modules \
    simde uthash rnnoise libdatachannel \
    mbedtls3 \
    ffmpeg

# ------------------------------------------------------------------------------
# 2. Build & Install NV-Codec-Headers (13.0)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[2/5] Fetching and installing nv-codec-headers (${NV_HEADERS_TAG})...${NC}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

if [ -d "nv-codec-headers" ]; then
    rm -rf nv-codec-headers
fi

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
git checkout "${NV_HEADERS_TAG}"
sudo make install PREFIX=/usr
cd ..

# ------------------------------------------------------------------------------
# 3. Clone / Prepare OBS Studio
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[3/5] Fetching OBS Studio source (${OBS_VERSION})...${NC}"
if [ -d "obs-studio" ]; then
    cd obs-studio
    git fetch --tags
    git checkout "${OBS_VERSION}"
    git submodule update --init --recursive
else
    git clone --recursive https://github.com/obsproject/obs-studio.git
    cd obs-studio
    git checkout "${OBS_VERSION}"
    git submodule update --init --recursive
fi

# ------------------------------------------------------------------------------
# 4. Configure & Compile with CMake
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[4/5] Configuring CMake with MbedTLS 3 & NVENC support...${NC}"
rm -rf build

cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_NVENC=ON \
    -DENABLE_AJA=OFF \
    -DENABLE_JACK=ON \
    -DMbedTLS_DIR=/usr/lib/mbedtls3/cmake/MbedTLS \
    -DCMAKE_INCLUDE_PATH=/usr/include/mbedtls3

echo -e "\n${YELLOW}[4/5] Compiling OBS Studio using $(nproc) threads...${NC}"
cmake --build build -j"$(nproc)"

# ------------------------------------------------------------------------------
# 5. Install to /usr
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[5/5] Installing OBS Studio to /usr...${NC}"
sudo cmake --install build

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN} Build and installation complete!${NC}"
echo -e "${GREEN} OBS Studio ${OBS_VERSION} with NVENC 13.0 is now active.${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "${YELLOW}Important Notice:${NC}"
echo -e "To prevent future pacman updates from overwriting this build, add this line"
echo -e "to your ${BLUE}/etc/pacman.conf${NC}:"
echo -e "    ${GREEN}IgnorePkg = obs-studio${NC}\n"
